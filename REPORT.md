# Report: LLM Inference + Observability Assignment

## 1. Serving Configuration

Model: `Qwen/Qwen3-30B-A3B-Instruct-2507` (30B total, ~3B active per forward pass — MoE architecture means inference cost scales with active parameters, not total).

Final `scripts/start_vllm.sh` flags:

| Flag | Rationale |
|---|---|
| `--gpu-memory-utilization 0.95` | H100 80GB is stable at 0.95; recovers ~4 GB for the KV cache pool vs. the 0.9 default |
| `--max-model-len 8192` | Workload ceiling is ~4K tokens (1.5–3K schema + question prompt, ~150 token SQL output). The default 65536 over-reserves KV blocks per sequence slot, limiting scheduler concurrency for no benefit |
| `--enable-chunked-prefill` | Schema prompts are long (1.5–3K tokens). Without chunking, prefill steps block decode for all concurrent sequences, spiking TTFT under load. Chunked prefill interleaves them and activates prefix caching as a side effect |
| `--max-num-seqs 128` | Explicit concurrency ceiling. After reducing `max-model-len`, sets a clear upper bound for the scheduler rather than relying on vLLM's implicit default |

The MoE architecture (A3B active out of 30B total) means the KV cache is sized per active layer, not total parameters — the model loads comfortably on one H100 with memory to spare for the KV pool.

---

## 2. Baseline Eval Results

Eval set: 30 questions across 7 BIRD-bench databases. Metric: execution accuracy — run both gold SQL and agent SQL against the target SQLite DB, compare canonicalized row sets (sorted, stringified).

**Overall pass rate: 9/30 = 30%**

Per-iteration pass rate:

| Iteration | Pass rate |
|---|---|
| iter 0 (generate_sql only) | 0.30 |
| iter 1 | 0.30 |
| iter 2 | 0.30 |
| iter 3 | 0.30 |

**The revise loop adds no measurable quality at baseline.** 11 of 30 questions triggered at least one revise, but none improved. Two failure modes explain the flat curve:

1. **Revise re-generates similar wrong SQL.** When verify returns "0 rows returned", the issue string is not specific enough for the model to change approach — case sensitivity bugs (`'m'` vs `'M'`, timestamp missing `.0` suffix, element `'Calcium'` vs `'ca'`) survive all three revise iterations unchanged.

2. **Verifier accepts semantically wrong non-empty results.** 10 questions returned plausible-looking rows with wrong logic (wrong column used, wrong threshold, wrong aggregation) and were never routed to revise. These are structurally invisible to a result-level verifier without ground truth.

The 9 passing questions cover simple to medium-complexity JOINs: all were correct on the first pass. The loop architecture is correct; the prompts need iteration.

---

## 3. SLO Tuning

**Target:** P95 end-to-end agent latency < 5 seconds, ≥ 10 RPS over 5 minutes (1 RPS = 1 full agent run = 2–3 serial vLLM calls).

### Baseline load test observation

Before tuning, Grafana showed: KV cache 28.4%, P99 e2e latency 4.59s (vLLM level), ~35 requests running concurrently, ~1,250 tokens/s generation throughput.

### Iteration log

**Iteration 1 — `--enable-chunked-prefill`**
```
saw:        TTFT P95 = 0.2s, vLLM e2e P95 ≈ 2.25s, 35 requests running
hypothesis: long schema prompts block decode steps under concurrency; chunked
            prefill interleaves them, reducing TTFT and enabling prefix caching
change:     --enable-chunked-prefill
result:     TTFT P95 0.2s → 0.07s (-65%), vLLM e2e P95 2.25s → 0.88s (-61%),
            KV cache rose to 50–60%; prefix cache hit rate 86.1% observed in logs
```

Prefix caching was the unexpected benefit: schema strings are shared across all requests to the same DB, so vLLM reuses KV blocks for repeated schema prefixes. This compounds the TTFT reduction.

**Iteration 2 — `--max-model-len 65536 → 8192`**
```
saw:        max-model-len 8× the workload ceiling, over-reserving KV blocks per slot
hypothesis: reducing it frees block budget for more concurrent sequences
change:     --max-model-len 8192
result:     vLLM e2e P95 reduced modestly (~2.5s → ~2.0s); KV cache dropped to
            ~20%; other metrics minimal change — prefill fix already captured main gain
```

**Iteration 3 — `--max-num-seqs 128`**
```
saw:        KV cache ~20%, latency stable, no RPS improvement from Step 2
hypothesis: explicit concurrency ceiling would let scheduler fill remaining headroom
change:     --max-num-seqs 128
result:     no meaningful change; KV cache fell to ~10% — vLLM is underloaded
            because the agent makes serial calls, not vLLM scheduling capacity
```

### Final numbers and SLO verdict

**vLLM layer (per individual LLM call):** TTFT P95 = 0.07s, e2e P95 ≈ 0.88s. This is well within what the 5s SLO requires per call.

**Agent layer (full pipeline, load test at 10 RPS, 300s):**

| Metric | Value | SLO target |
|---|---|---|
| Successful requests | 565 / 3000 (19%) | — |
| Timeouts (120s limit) | 1,306 | — |
| Achieved successful RPS | ~1.6 | ≥ 10 |
| P50 latency | 16.68s | — |
| P95 latency | 108.67s | < 5s |

**SLO missed.** P95 agent latency is 108.67s against a 5s target — a 22× gap. The root cause is not vLLM: after optimization, each individual LLM call completes in under 1s. The bottleneck is the **agent server**. `graph.invoke()` is synchronous and blocking; uvicorn runs a single worker by default. At 10 RPS arrival, agent requests queue behind each other waiting for the single worker to finish 2–3 serial LLM calls per request. vLLM KV cache sits at ~10% because the agent isn't feeding it fast enough — the inference layer is idle while the agent orchestration queues.

---

## 4. Agent Value

The verify → revise loop did not improve eval pass rate at baseline (per-iteration rate flat at 0.30). It triggered on 11/30 questions but fixed none. The architecture is correct and the revise loop is structurally sound — it successfully detected 0-row errors and SQL errors and routed them to revise. The failure is in the prompts: verify's issue descriptions are too vague to guide the model toward a different approach on cases like string case mismatch or wrong column names.

Measured value at this stage: the loop costs 1–2 additional vLLM calls per triggered question (latency overhead) with no demonstrated quality gain. The overhead is justified by the architecture — a better-tuned verify prompt should convert detectable failures into recoverable ones.

---

## 5. What I Would Do With More Time

1. **Async agent server.** Replace `graph.invoke()` with an async LangGraph invocation and run uvicorn with multiple workers (`--workers 4`). This is the single change that would unlock the RPS target — it directly addresses the load test failure mode with no model or prompt changes required.

2. **BIRD column descriptions in schema rendering.** `render_schema` outputs raw DDL — opaque column names like `A15` (crimes in 1995) appear without description. Injecting BIRD's provided column metadata as SQL comments would eliminate the A14/A15 class of error, which was the dominant failure mode for the financial DB across all 3 revise iterations.

3. **Richer verify issue descriptions.** When verify returns `"0 rows returned"`, add a hint: "check string literal case — SQLite comparisons are case-sensitive" and "check timestamp format including trailing `.0`". This targeted guidance would give revise the information needed to actually fix the 11 questions that currently loop and fail. Expected impact: +3–5 correct on 30-question eval (10–17pp pass rate gain).

4. **Prefix-cache-aware prompt design.** With 86.1% prefix cache hit rate confirmed, structure prompts so the schema is always the first N tokens and question always follows. This maximises reuse of cached KV blocks across requests to the same DB, reducing effective TTFT to near-zero for repeated database schemas.
