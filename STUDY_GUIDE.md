# Study Guide: LLM Inference + Observability

## What this assignment is

You are building a **text-to-SQL system** backed by a self-hosted LLM, then operating it: measuring it, iterating on it, and proving it meets a latency/throughput SLO without breaking quality. The scenario is real: an internal analytics product where analysts type questions in English and the system returns rows from a data warehouse.

The stack has two layers of observability that measure different things:
- **Prometheus + Grafana** watches the *inference engine* (GPU, KV cache, tokens/sec, queue depth)
- **Langfuse** watches the *agent* (which nodes ran, how long each LLM call took, what the model said)

Neither layer alone is sufficient. Grafana tells you the serving layer is slow; Langfuse tells you which agent step caused it.

---

## Concepts and technology

### vLLM and LLM inference

A language model produces one token at a time. Serving it efficiently requires batching many concurrent requests together — tokens for different sequences are computed in the same GPU kernel. vLLM does this through two mechanisms:

**PagedAttention.** The KV cache (the key/value tensors that represent a sequence's history) is stored in fixed-size *pages* of GPU memory, like OS virtual memory. This eliminates external fragmentation: sequences of different lengths share the same physical memory pool, and memory is only allocated as tokens are actually generated. The practical effect is that you can run far more concurrent sequences than with static per-sequence buffers.

**Continuous batching.** Rather than waiting for all sequences in a batch to finish before starting new ones, vLLM inserts new requests into the batch as soon as a slot frees up. This keeps GPU utilization near-constant under load.

**The prefill / decode split.** Every request has two phases. *Prefill*: the entire prompt is processed in one forward pass to populate the KV cache — this is compute-bound and fast. *Decode*: tokens are generated one at a time — this is memory-bandwidth-bound and slow. Long prompts (like your 1.5–3K-token schema + question) make prefill expensive. Short outputs (SQL is ~50–200 tokens) make decode cheap. Knowing this split matters when reading the latency metrics.

**Key vLLM flags for this workload** (1.5–3K prompt, short structured output, 2–3 serial calls per user request on H100 80GB):

| Flag | Rationale |
|---|---|
| `--max-model-len 8192` | Qwen3's default context is 32K+. Reducing it cuts KV cache memory proportionally, fitting more concurrent sequences in 80GB. Your workload never needs more than ~4K tokens. |
| `--enable-chunked-prefill` | Splits long prefill operations across multiple steps, interleaving them with decode. Reduces P99 time-to-first-token spikes under load. |
| `--gpu-memory-utilization 0.95` | H100 80GB is reliable; pushing above the 0.9 default recovers ~4GB for the KV cache pool. |
| `--max-num-seqs 128` | Upper bound on concurrent sequences. Start here; back off if you see OOM or scheduler thrash. |
| `--enable-reasoning --reasoning-parser deepseek_r1` | Qwen3 emits `<think>...</think>` blocks before its answer. Without this flag those blocks appear in `content`. With it, they are routed to `reasoning_content` and stripped from the visible output. |

### Qwen3-30B-A3B: a Mixture-of-Experts model

Qwen3-30B-A3B is a **Mixture of Experts (MoE)** model. The architecture replaces the dense feed-forward layers in a standard Transformer with a set of $N$ independent "expert" networks. A learned *router* selects $k$ experts per token. Only those $k$ experts are activated; the rest sit idle on the GPU.

For Qwen3-30B-A3B: 30B *total* parameters, but only ~3B are *active* per forward pass (hence the "A3B"). This gives the model the representational capacity of a 30B model at the inference cost of a 3B model — at the price of higher memory for storing inactive experts. On a single H100 80GB it loads comfortably.

Implication for vLLM: the KV cache is sized per active layer, not per total parameter. MoE models are often more memory-efficient to serve than their parameter count suggests.

### BIRD-bench and execution accuracy

[BIRD-bench](https://bird-bench.github.io/) (Big Bench for Large-scale Database Grounded Text-to-SQL) is an academic benchmark of natural-language questions paired with gold SQL over real databases. The eval metric is **execution accuracy**: run both the gold SQL and the model's SQL, compare result sets. Two different SQL strings that return the same rows count as equivalent. This is the right metric for production use — syntactic string match would reject valid paraphrases.

The canonicalization step (sort rows, stringify cells, coerce `None → ""`) is necessary because SQL makes no guarantee on row order unless `ORDER BY` is explicit, and type representations differ between drivers.

### LangGraph: stateful agent graphs

LangGraph models an agent as a directed graph where nodes are Python functions and edges are either fixed (`add_edge`) or conditional (`add_conditional_edges`). State — a dataclass in this assignment — is threaded through every node. Each node receives the current state and returns a partial dict with only the fields it changed.

The verify → revise loop is a **self-consistency-inspired refinement**. The idea: generate a candidate answer, evaluate it with a separate model call (the verifier), and if it fails, generate a corrected answer given the failure mode. The loop adds latency (each iteration is 2 more LLM calls) but recovers quality on cases where the first SQL was wrong. Whether the latency cost is worth the quality gain is exactly what Phase 5 measures.

The iteration cap (`MAX_ITERATIONS = 3`) is critical for SLO compliance. Without it, pathological inputs could loop forever.

### Prometheus and Grafana

Prometheus scrapes `/metrics` from vLLM every 5 seconds (see `infra/prometheus.yml`). vLLM exposes metrics in the Prometheus exposition format: gauge, counter, and histogram families. Key ones:

**Latency** (histograms — use `histogram_quantile(0.95, ...)` for P95):
- `vllm:e2e_request_latency_seconds_bucket` — full round-trip from request received to last token sent
- `vllm:time_to_first_token_seconds_bucket` — prefill time; large = prompt too long or GPU underclocked
- `vllm:time_per_output_token_seconds_bucket` — per-token decode latency; large = memory bandwidth bound

**Throughput** (rates — use `rate(...[1m])`):
- `vllm:prompt_tokens_total` — tokens ingested per second
- `vllm:generation_tokens_total` — tokens emitted per second
- `vllm:request_success_total` — completed requests per second

**Concurrency / queue**:
- `vllm:num_requests_running` — sequences actively being decoded right now
- `vllm:num_requests_waiting` — sequences waiting for a free KV cache slot

**KV cache** (gauges):
- `vllm:gpu_cache_usage_perc` — fraction of KV cache blocks in use (0–1). Above ~0.9 you start evicting; above ~0.95 the scheduler stalls new requests.

Grafana panels query Prometheus via PromQL. For a histogram P95: `histogram_quantile(0.95, sum(rate(vllm:e2e_request_latency_seconds_bucket[1m])) by (le))`.

### Langfuse: LLM observability

Langfuse captures **traces**: one trace per agent run, containing nested *spans* for each LangChain/LangGraph node. Each span records the input prompt, the model output, token counts, latency, and any metadata you attach. The LangGraph callback integration (`langfuse.langchain.CallbackHandler`) does this automatically — you just pass it as a callback.

Traces let you answer questions Prometheus cannot: "this request took 12 seconds — was it slow because `generate_sql` was slow, or because `revise` ran three times?" The waterfall view in the Langfuse UI shows the span timeline.

Metadata tags (`req.tags` in `server.py`) flow into Langfuse as trace metadata. Tag with things like `{"phase": "baseline", "db": "formula_1"}` so you can filter traces by experiment phase in Phase 6.

---

## Step-by-step execution

### Phase 0 — Environment setup

```bash
# On the H100 VM:
git clone <repo-url> && cd <repo-folder>
uv sync
cp .env.example .env
# Fill in HF_TOKEN (needed to download Qwen3 from HuggingFace)

uv run python scripts/load_data.py   # downloads BIRD subset → data/bird/

docker compose up -d                  # starts Prometheus, Grafana, Langfuse stack
```

Forward ports from your laptop (or use VSCode Remote-SSH Ports panel):
```bash
ssh -L 3000:localhost:3000 -L 9090:localhost:9090 \
    -L 3001:localhost:3001 -L 8000:localhost:8000 \
    -L 8001:localhost:8001 <user>@<vm>
```

Verify:
- http://localhost:9090 → Prometheus
- http://localhost:3000 → Grafana (admin/admin)
- http://localhost:3001 → Langfuse (create a local account)

**Checkpoint:** BIRD data under `data/bird/`, three UIs load in browser.

---

### Phase 1 — vLLM serving

Edit `scripts/start_vllm.sh`. Starting config for H100 80GB with this workload:

```bash
MODEL="${MODEL:-Qwen/Qwen3-30B-A3B-Instruct-2507}"
PORT="${PORT:-8000}"

exec uv run python -m vllm.entrypoints.openai.api_server \
    --model "$MODEL" \
    --host 0.0.0.0 \
    --port "$PORT" \
    --max-model-len 8192 \
    --gpu-memory-utilization 0.95 \
    --enable-chunked-prefill \
    --max-num-seqs 128 \
    --enable-reasoning \
    --reasoning-parser deepseek_r1
```

Start it: `bash scripts/start_vllm.sh` (watch logs; model load takes ~2 min on H100).

Smoke test a few questions from the eval set:
```bash
curl http://localhost:8000/v1/chat/completions \
  -H "Content-Type: application/json" \
  -d '{
    "model": "Qwen/Qwen3-30B-A3B-Instruct-2507",
    "messages": [{"role": "user", "content": "Write SELECT 1"}],
    "max_tokens": 100
  }'
```

Try 3–5 questions from `evals/eval_set.jsonl` manually and confirm the outputs are plausible SQL. Take a screenshot of vLLM serving + one response → `screenshots/vllm_manual_query.png`.

Document your final flags in `REPORT.md` with a one-line rationale for each.

**Checkpoint:** vLLM responds at `http://localhost:8000`, outputs look like valid SQL.

---

### Phase 2 — Grafana dashboard

Open Grafana at http://localhost:3000 → Dashboards → "vLLM serving" (the starter).

Build three additional panel groups (you can edit the JSON directly at `infra/grafana/provisioning/dashboards/serving.json` or use the Grafana UI and export):

**Latency panel (time series):**
```promql
# P50 / P95 / P99 end-to-end latency
histogram_quantile(0.50, sum(rate(vllm:e2e_request_latency_seconds_bucket[1m])) by (le))
histogram_quantile(0.95, sum(rate(vllm:e2e_request_latency_seconds_bucket[1m])) by (le))

# Time to first token (prefill cost)
histogram_quantile(0.95, sum(rate(vllm:time_to_first_token_seconds_bucket[1m])) by (le))
```

**Throughput panel (time series):**
```promql
rate(vllm:generation_tokens_total[1m])   # tokens out / sec
rate(vllm:request_success_total[1m])     # requests / sec
vllm:num_requests_running                # active sequences
vllm:num_requests_waiting                # queued sequences
```

**KV cache panel (gauge or time series):**
```promql
vllm:gpu_cache_usage_perc * 100   # 0-100%, alert threshold at ~90%
```

Fire a burst of requests to confirm all panels react (use the load test driver at a low RPS). Screenshot the full dashboard → `screenshots/grafana_serving.png`. Commit the JSON.

**Checkpoint:** Dashboard has latency percentiles, throughput, KV cache panels; all react under load.

---

### Phase 3 — Agent implementation

The graph wiring is already in `agent/graph.py`. You implement three things:

**1. Prompts in `agent/prompts.py`**

`GENERATE_SQL_SYSTEM`: Tell the model it is a SQL expert; it receives a schema and a question; it must output only SQL in a code fence.

`GENERATE_SQL_USER` (placeholders `{schema}`, `{question}`): Present the schema, then the question. Instruct the model to use only tables/columns from the schema.

`VERIFY_SYSTEM` / `VERIFY_USER`: Tell the model to judge whether the execution result plausibly answers the question. Ask for a JSON object `{"ok": true/false, "issue": "<reason if not ok>"}`. Cases to catch: SQL errored, zero rows when rows are expected, columns clearly irrelevant to the question.

`REVISE_SYSTEM` / `REVISE_USER`: Present the original question, the failing SQL, the execution result, and the verifier's `issue`. Ask for a corrected SQL.

**2. `verify_node` in `agent/graph.py`**

```python
def verify_node(state: AgentState) -> dict:
    response = llm().invoke([
        ("system", prompts.VERIFY_SYSTEM),
        ("user", prompts.VERIFY_USER.format(
            question=state.question,
            sql=state.sql,
            result=state.execution.render(),
        )),
    ])
    # Parse defensively — the model may wrap JSON in prose or fences
    import json, re
    text = response.content
    m = re.search(r'\{.*\}', text, re.DOTALL)
    try:
        parsed = json.loads(m.group()) if m else {}
    except json.JSONDecodeError:
        parsed = {}
    ok = bool(parsed.get("ok", False))
    issue = str(parsed.get("issue", "unspecified"))
    return {"verify_ok": ok, "verify_issue": issue}
```

**3. `revise_node` and `route_after_verify`**

```python
def revise_node(state: AgentState) -> dict:
    response = llm().invoke([
        ("system", prompts.REVISE_SYSTEM),
        ("user", prompts.REVISE_USER.format(
            schema=state.schema,
            question=state.question,
            sql=state.sql,
            result=state.execution.render(),
            issue=state.verify_issue,
        )),
    ])
    sql = _extract_sql(response.content)
    return {
        "sql": sql,
        "iteration": state.iteration + 1,
        "history": state.history + [{"node": "revise", "sql": sql}],
    }

def route_after_verify(state: AgentState) -> str:
    if state.verify_ok or state.iteration >= MAX_ITERATIONS:
        return "end"
    return "revise"
```

Start the agent server:
```bash
uv run uvicorn agent.server:app --host 0.0.0.0 --port 8001
```

Test:
```bash
curl -X POST http://localhost:8001/answer \
  -H "Content-Type: application/json" \
  -d '{"question": "List Ajax superpowers.", "db": "superhero"}'
```

Run 5 questions from the eval set and verify at least one triggers `revise` (check `iterations > 1` in the response or look at `history`).

**Checkpoint:** Agent server responds, verify→revise loop visible in at least one run.

---

### Phase 4 — Langfuse tracing

1. Open http://localhost:3001, create an account and a project.
2. Copy the public and secret keys from Project Settings → API Keys.
3. Add to `.env`:
   ```
   LANGFUSE_PUBLIC_KEY=pk-lf-...
   LANGFUSE_SECRET_KEY=sk-lf-...
   LANGFUSE_HOST=http://localhost:3001
   ```
4. Restart the agent server (it reads `.env` on startup via `load_dotenv()`).

The `server.py` already initializes `CallbackHandler` and attaches it when the keys are present — no further code changes needed.

Fire 10 questions through the agent. In Langfuse, open a trace: you should see a waterfall with `generate_sql`, `verify`, and sometimes `revise` as nested spans. Each span shows its prompt, completion, latency, and token count.

Tag traces for Phase 6 filtering by passing `tags` in the request body:
```bash
curl -X POST http://localhost:8001/answer \
  -H "Content-Type: application/json" \
  -d '{"question": "...", "db": "formula_1", "tags": {"phase": "baseline"}}'
```

Screenshots: one trace showing the waterfall → `screenshots/langfuse_trace.png`; the trace list with tags visible → `screenshots/langfuse_tags.png`.

**Checkpoint:** Langfuse shows traces with per-node spans and metadata tags.

---

### Phase 5 — Offline evaluation

Implement `evals/run_eval.py`. The helpers (`run_sql`, `canonicalize`, `matches`) are provided. Fill in:

```python
def eval_one(question: dict, agent_url: str) -> dict:
    import httpx
    payload = {"question": question["question"], "db": question["db_id"]}
    resp = httpx.post(agent_url, json=payload, timeout=120)
    resp.raise_for_status()
    data = resp.json()

    agent_sql = data.get("sql", "")
    iterations = data.get("iterations", 0)
    history = data.get("history", [])

    gold_ok, gold_rows, _ = run_sql(question["db_id"], question["gold_sql"])
    
    # Evaluate correctness at each iteration using the SQL from history
    per_iter: dict[int, bool] = {}
    for i, entry in enumerate(history):
        sql_at_iter = entry.get("sql", "")
        ok, rows, _ = run_sql(question["db_id"], sql_at_iter)
        per_iter[i] = matches(gold_rows, rows) if gold_ok else False

    final_ok, final_rows, _ = run_sql(question["db_id"], agent_sql)
    final_correct = matches(gold_rows, final_rows) if gold_ok else False

    return {
        "question_id": question.get("question_id", question["question"][:40]),
        "db_id": question["db_id"],
        "agent_sql": agent_sql,
        "gold_sql": question["gold_sql"],
        "iterations": iterations,
        "final_correct": final_correct,
        "per_iter_correct": per_iter,
    }


def summarize(results: list[dict]) -> dict:
    n = len(results)
    max_iter = max((r["iterations"] for r in results), default=0)
    
    # Per-iteration pass rate with carry-forward
    per_iter_rates = {}
    for k in range(max_iter + 1):
        correct = 0
        for r in results:
            # Use final result as carry-forward if iter k > what agent ran
            last_available = max((i for i in r["per_iter_correct"]), default=-1)
            if k <= last_available:
                correct += int(r["per_iter_correct"].get(k, False))
            else:
                correct += int(r["final_correct"])
        per_iter_rates[str(k)] = correct / n if n else 0.0

    return {
        "n": n,
        "overall_pass_rate": sum(r["final_correct"] for r in results) / n if n else 0.0,
        "per_iteration_pass_rate": per_iter_rates,
    }
```

Run the baseline eval (watch Grafana while it runs — this is ~60 requests):
```bash
uv run python evals/run_eval.py --out results/eval_baseline.json
```

Screenshot Grafana during the run → `screenshots/grafana_eval_run.png`.

Check whether the per-iteration pass rate increases: if `iter_0 ≈ iter_2`, the loop is doing nothing. If `iter_2 > iter_0`, the revise step is earning its keep.

**Checkpoint:** `results/eval_baseline.json` present with overall + per-iteration rates.

---

### Phase 6 — SLO tuning

Target: **P95 end-to-end agent latency < 5 seconds, ≥ 10 RPS over 5 minutes.**

Note: "1 RPS" here means 1 full agent run per second (2–3 vLLM calls), not 1 vLLM call per second.

**Step 1: baseline load test**
```bash
uv run python load_test/driver.py --rps 10 --duration 300
```
Watch the Grafana dashboard. Note which metric moves first as load ramps.

**Step 2: diagnose before changing anything**

Read the dashboard before guessing. Common patterns:
- `vllm:num_requests_waiting > 0` persistently → KV cache exhausted or `max-num-seqs` too low
- `vllm:gpu_cache_usage_perc > 0.9` → reduce `--max-model-len` or reduce `--max-num-seqs`
- P95 latency >> P50 → tail latency from queuing; look at `num_requests_waiting` spikes
- TTFT dominates E2E latency → prefill is the bottleneck; try `--enable-chunked-prefill` if not already set

**Step 3: one change at a time**

Each iteration: form a hypothesis, change one flag, re-run the load test, confirm the targeted metric moved, then check whether E2E latency followed. Document in `REPORT.md`:
```
saw: KV cache at 95%, P95 latency 8s
hypothesis: max-model-len 8192 still leaves not enough KV blocks at 10 RPS
change: --max-model-len 4096
result: KV cache peaks at 70%, P95 latency 3.2s, SLO hit
```

Take before/after Grafana screenshots → `screenshots/grafana_before.png`, `screenshots/grafana_after.png`.

**Step 4: re-run eval after tuning**
```bash
uv run python evals/run_eval.py --out results/eval_after_tuning.json
```

Compare pass rates. A config change that hits the SLO but regresses quality by >5pp is a bad trade — document it honestly.

**Checkpoint:** Iteration log in `REPORT.md`, before/after screenshots, `eval_after_tuning.json`.

---

### Phase 7 — Report

`REPORT.md` sections (≤ 3 pages total):

1. **Serving config** — each flag with a one-line rationale tied to the workload or MoE architecture
2. **Baseline eval** — overall pass rate, per-iteration rates, one sentence on whether the agent loop helped
3. **SLO iteration log** — the *"saw X → hypothesized Y → changed Z → result W"* entries, one per iteration
4. **Final numbers** — SLO hit or miss; if miss, quantify the gap
5. **Agent value** — did verify→revise add measurable quality? cite the per-iteration pass rate delta
6. **What next** — be specific: "reduce prompt token count by removing redundant FK lines from schema rendering" counts; "add Kubernetes" does not

---

## Deliverables checklist

| File | Phase |
|---|---|
| `scripts/start_vllm.sh` (configured) | 1 |
| `screenshots/vllm_manual_query.png` | 1 |
| `infra/grafana/provisioning/dashboards/serving.json` | 2 |
| `screenshots/grafana_serving.png` | 2 |
| `agent/graph.py` (verify, revise, router implemented) | 3 |
| `agent/prompts.py` (all six prompts filled) | 3 |
| `screenshots/langfuse_trace.png` | 4 |
| `screenshots/langfuse_tags.png` | 4 |
| `evals/run_eval.py` (eval_one, summarize implemented) | 5 |
| `results/eval_baseline.json` | 5 |
| `screenshots/grafana_eval_run.png` | 5 |
| `screenshots/grafana_before.png`, `grafana_after.png` | 6 |
| `results/eval_after_tuning.json` | 6 |
| `REPORT.md` | 7 |

---

## Off-GPU development

You can build and debug Phases 2–5 without the H100:

- **CPU-vLLM** with a small model: `VLLM_MODEL=Qwen/Qwen3-0.6B` in `.env`, run vLLM with `--device cpu`. Grafana panels react; absolute numbers are unrepresentative.
- **Hosted API**: set `VLLM_BASE_URL=https://api.openai.com/v1` and a real `OPENAI_API_KEY` in `.env`. Agent logic and Langfuse tracing work normally; no Prometheus metrics.

Eval pass rates and all Phase 6 numbers must come from Qwen3-30B-A3B on the H100.
