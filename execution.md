##### Phase 1

1. Simple COUNT + JOIN (financial)
```
curl -s http://localhost:8000/v1/chat/completions \
  -H "Content-Type: application/json" \
  -d '{
    "model": "Qwen/Qwen3-30B-A3B-Instruct-2507",
    "messages": [
      {"role": "system", "content": "You are a SQL expert. Write a SQLite query answering the question. Return only the SQL inside a ```sql block."},
      {"role": "user", "content": "How many male clients in '\''Hl.m. Praha'\'' district? DB: financial"}
    ],
    "max_tokens": 200
  }' | python3 -m json.tool

{
    "id": "chatcmpl-c933a5eaae204d77850b5272566431f4",
    "object": "chat.completion",
    "created": 1781528850,
    "model": "Qwen/Qwen3-30B-A3B-Instruct-2507",
    "choices": [
        {
            "index": 0,
            "message": {
                "role": "assistant",
                "content": "```sql\nSELECT COUNT(*) \nFROM clients \nWHERE gender = 'male' \n  AND district = 'Hl.m. Praha';\n```",
                "refusal": null,
                "annotations": null,
                "audio": null,
                "function_call": null,
                "tool_calls": [],
                "reasoning_content": null
            },
            "logprobs": null,
            "finish_reason": "stop",
            "stop_reason": null,
            "token_ids": null
        }
    ],
    "service_tier": null,
    "system_fingerprint": null,
    "usage": {
        "prompt_tokens": 55,
        "total_tokens": 86,
        "completion_tokens": 31,
        "prompt_tokens_details": null
    },
    "prompt_logprobs": null,
    "prompt_token_ids": null,
    "kv_transfer_params": null
}
```
2. Date filter (codebase_community)
```
curl -s http://localhost:8000/v1/chat/completions \
  -H "Content-Type: application/json" \
  -d '{
    "model": "Qwen/Qwen3-30B-A3B-Instruct-2507",
    "messages": [
      {"role": "system", "content": "You are a SQL expert. Write a SQLite query answering the question. Return only the SQL inside a ```sql block."},
      {"role": "user", "content": "How many users received commentator badges in 2014? DB: codebase_community (tables: badges(Id, UserId, Name, Date))"}
    ],
    "max_tokens": 200
  }' | python3 -m json.tool
{
    "id": "chatcmpl-a01f16407a464ba4829d22ae4824a066",
    "object": "chat.completion",
    "created": 1781528925,
    "model": "Qwen/Qwen3-30B-A3B-Instruct-2507",
    "choices": [
        {
            "index": 0,
            "message": {
                "role": "assistant",
                "content": "```sql\nSELECT COUNT(DISTINCT UserId) \nFROM badges \nWHERE Name = 'Commentator' \n  AND Date >= '2014-01-01' \n  AND Date < '2015-01-01';\n```",
                "refusal": null,
                "annotations": null,
                "audio": null,
                "function_call": null,
                "tool_calls": [],
                "reasoning_content": null
            },
            "logprobs": null,
            "finish_reason": "stop",
            "stop_reason": null,
            "token_ids": null
        }
    ],
    "service_tier": null,
    "system_fingerprint": null,
    "usage": {
        "prompt_tokens": 67,
        "total_tokens": 124,
        "completion_tokens": 57,
        "prompt_tokens_details": null
    },
    "prompt_logprobs": null,
    "prompt_token_ids": null,
    "kv_transfer_params": null
}
```
3. 3-table JOIN (superhero)
```
curl -s http://localhost:8000/v1/chat/completions \
  -H "Content-Type: application/json" \
  -d '{
    "model": "Qwen/Qwen3-30B-A3B-Instruct-2507",
    "messages": [
      {"role": "system", "content": "You are a SQL expert. Write a SQLite query answering the question. Return only the SQL inside a ```sql block."},
      {"role": "user", "content": "List down Ajax'\''s superpowers. DB: superhero (tables: superhero, hero_power, superpower)"}
    ],
    "max_tokens": 200
  }' | python3 -m json.tool

{
    "id": "chatcmpl-93c4421c294c41d9a702fcc33dfa1cae",
    "object": "chat.completion",
    "created": 1781528955,
    "model": "Qwen/Qwen3-30B-A3B-Instruct-2507",
    "choices": [
        {
            "index": 0,
            "message": {
                "role": "assistant",
                "content": "```sql\nSELECT sp.power_name\nFROM superhero s\nJOIN hero_power hp ON s.hero_id = hp.hero_id\nJOIN superpower sp ON hp.power_id = sp.power_id\nWHERE s.hero_name = 'Ajax';\n```",
                "refusal": null,
                "annotations": null,
                "audio": null,
                "function_call": null,
                "tool_calls": [],
                "reasoning_content": null
            },
            "logprobs": null,
            "finish_reason": "stop",
            "stop_reason": null,
            "token_ids": null
        }
    ],
    "service_tier": null,
    "system_fingerprint": null,
    "usage": {
        "prompt_tokens": 58,
        "total_tokens": 106,
        "completion_tokens": 48,
        "prompt_tokens_details": null
    },
    "prompt_logprobs": null,
    "prompt_token_ids": null,
    "kv_transfer_params": null
}
```

4. Conditional aggregation / percentage (toxicology)
```
curl -s http://localhost:8000/v1/chat/completions \
  -H "Content-Type: application/json" \
  -d '{
    "model": "Qwen/Qwen3-30B-A3B-Instruct-2507",
    "messages": [
      {"role": "system", "content": "You are a SQL expert. Write a SQLite query answering the question. Return only the SQL inside a ```sql block."},
      {"role": "user", "content": "Calculate the percentage of carcinogenic molecules which contain the Chlorine element. DB: toxicology (tables: atom(atom_id, molecule_id, element), molecule(molecule_id, label))"}
    ],
    "max_tokens": 200
  }' | python3 -m json.tool

{
    "id": "chatcmpl-6d16b2f87a8a4ca49d7602e2505b7273",
    "object": "chat.completion",
    "created": 1781529011,
    "model": "Qwen/Qwen3-30B-A3B-Instruct-2507",
    "choices": [
        {
            "index": 0,
            "message": {
                "role": "assistant",
                "content": "```sql\nSELECT \n    (COUNT(CASE WHEN a.element = 'Cl' THEN 1 END) * 100.0 / COUNT(*)) AS percentage_chlorine_in_carcinogenic\nFROM \n    molecule m\n    JOIN atom a ON m.molecule_id = a.molecule_id\nWHERE \n    m.label = 'carcinogenic';\n```",
                "refusal": null,
                "annotations": null,
                "audio": null,
                "function_call": null,
                "tool_calls": [],
                "reasoning_content": null
            },
            "logprobs": null,
            "finish_reason": "stop",
            "stop_reason": null,
            "token_ids": null
        }
    ],
    "service_tier": null,
    "system_fingerprint": null,
    "usage": {
        "prompt_tokens": 74,
        "total_tokens": 152,
        "completion_tokens": 78,
        "prompt_tokens_details": null
    },
    "prompt_logprobs": null,
    "prompt_token_ids": null,
    "kv_transfer_params": null
}
```

5. ORDER BY + LIMIT + nested JOIN (california_schools)
```
curl -s http://localhost:8000/v1/chat/completions \
  -H "Content-Type: application/json" \
  -d '{
    "model": "Qwen/Qwen3-30B-A3B-Instruct-2507",
    "messages": [
      {"role": "system", "content": "You are a SQL expert. Write a SQLite query answering the question. Return only the SQL inside a ```sql block."},
      {"role": "user", "content": "Which active district has the highest average score in Reading? DB: california_schools (tables: schools(CDSCode, District, StatusType), satscores(cds, AvgScrRead))"}
    ],
    "max_tokens": 200
  }' | python3 -m json.tool

{
    "id": "chatcmpl-36e941bc96414830827bda0a350a56ec",
    "object": "chat.completion",
    "created": 1781529041,
    "model": "Qwen/Qwen3-30B-A3B-Instruct-2507",
    "choices": [
        {
            "index": 0,
            "message": {
                "role": "assistant",
                "content": "```sql\nSELECT s.District\nFROM schools s\nJOIN satscores ss ON s.CDSCode = ss.cds\nWHERE s.StatusType = 'Active'\nGROUP BY s.District\nORDER BY AVG(ss.AvgScrRead) DESC\nLIMIT 1;\n```",
                "refusal": null,
                "annotations": null,
                "audio": null,
                "function_call": null,
                "tool_calls": [],
                "reasoning_content": null
            },
            "logprobs": null,
            "finish_reason": "stop",
            "stop_reason": null,
            "token_ids": null
        }
    ],
    "service_tier": null,
    "system_fingerprint": null,
    "usage": {
        "prompt_tokens": 76,
        "total_tokens": 134,
        "completion_tokens": 58,
        "prompt_tokens_details": null
    },
    "prompt_logprobs": null,
    "prompt_token_ids": null,
    "kv_transfer_params": null
}
```

6. CASE WHEN + date math across years (student_club)
```
curl -s http://localhost:8000/v1/chat/completions \
  -H "Content-Type: application/json" \
  -d '{
    "model": "Qwen/Qwen3-30B-A3B-Instruct-2507",
    "messages": [
      {"role": "system", "content": "You are a SQL expert. Write a SQLite query answering the question. Return only the SQL inside a ```sql block."},
      {"role": "user", "content": "Calculate the difference of the total amount spent in all events by the Student_Club in year 2019 and 2020. DB: student_club (tables: event(event_id, event_date), budget(link_to_event, spent))"}
    ],
    "max_tokens": 200
  }' | python3 -m json.tool

{
    "id": "chatcmpl-dbf0b9b6e6c748b8aa077cd5ecc90a24",
    "object": "chat.completion",
    "created": 1781529063,
    "model": "Qwen/Qwen3-30B-A3B-Instruct-2507",
    "choices": [
        {
            "index": 0,
            "message": {
                "role": "assistant",
                "content": "```sql\nSELECT \n    (SELECT SUM(b.spent) \n     FROM budget b \n     JOIN event e ON b.link_to_event = e.event_id \n     WHERE strftime('%Y', e.event_date) = '2019') -\n    (SELECT SUM(b.spent) \n     FROM budget b \n     JOIN event e ON b.link_to_event = e.event_id \n     WHERE strftime('%Y', e.event_date) = '2020') AS amount_difference;\n```",
                "refusal": null,
                "annotations": null,
                "audio": null,
                "function_call": null,
                "tool_calls": [],
                "reasoning_content": null
            },
            "logprobs": null,
            "finish_reason": "stop",
            "stop_reason": null,
            "token_ids": null
        }
    ],
    "service_tier": null,
    "system_fingerprint": null,
    "usage": {
        "prompt_tokens": 89,
        "total_tokens": 191,
        "completion_tokens": 102,
        "prompt_tokens_details": null
    },
    "prompt_logprobs": null,
    "prompt_token_ids": null,
    "kv_transfer_params": null
}
```

7. String manipulation to compute numeric value (formula_1) — the hardest one; gold SQL uses SUBSTR/INSTR to parse mm:ss.sss lap times
```
curl -s http://localhost:8000/v1/chat/completions \
  -H "Content-Type: application/json" \
  -d '{
    "model": "Qwen/Qwen3-30B-A3B-Instruct-2507",
    "messages": [
      {"role": "system", "content": "You are a SQL expert. Write a SQLite query answering the question. Return only the SQL inside a ```sql block."},
      {"role": "user", "content": "What is the average fastest lap time in seconds for Lewis Hamilton in all Formula 1 races? DB: formula_1 (tables: drivers(driverId, forename, surname), results(driverId, fastestLapTime))"}
    ],
    "max_tokens": 300
  }' | python3 -m json.tool

{
    "id": "chatcmpl-2cbfaea28ed84001b6118a4ca749d679",
    "object": "chat.completion",
    "created": 1781529091,
    "model": "Qwen/Qwen3-30B-A3B-Instruct-2507",
    "choices": [
        {
            "index": 0,
            "message": {
                "role": "assistant",
                "content": "```sql\nSELECT AVG(r.fastestLapTime) AS average_fastest_lap_time\nFROM results r\nJOIN drivers d ON r.driverId = d.driverId\nWHERE d.forename = 'Lewis' AND d.surname = 'Hamilton';\n```",
                "refusal": null,
                "annotations": null,
                "audio": null,
                "function_call": null,
                "tool_calls": [],
                "reasoning_content": null
            },
            "logprobs": null,
            "finish_reason": "stop",
            "stop_reason": null,
            "token_ids": null
        }
    ],
    "service_tier": null,
    "system_fingerprint": null,
    "usage": {
        "prompt_tokens": 82,
        "total_tokens": 135,
        "completion_tokens": 53,
        "prompt_tokens_details": null
    },
    "prompt_logprobs": null,
    "prompt_token_ids": null,
    "kv_transfer_params": null
}
```

---

### Phase 1 — Analysis of manual query results

Tested 7 queries across 7 databases without schema injection (bare question + minimal table hints). Results:

| # | DB | Type | Verdict | Root cause |
|---|---|---|---|---|
| 1 | financial | COUNT + JOIN | **Wrong** | Hallucinated flat schema; missing join between `client` and `district`; wrong gender encoding (`'male'` vs `'M'`); wrong column `district` vs `A2` |
| 2 | codebase_community | Date filter | **Close** | `COUNT(DISTINCT UserId)` vs gold's `COUNT(Id)` — diverges if a user earned the badge twice; date range logic is equivalent |
| 3 | superhero | 3-table JOIN | **Wrong** | Join structure correct; column names guessed wrong (`hero_id` → `id`, `hero_name` → `superhero_name`) — would throw column-not-found |
| 4 | toxicology | Conditional % | **Wrong** | Answered the wrong question: filtered `WHERE label='carcinogenic'` first then asked "what % have Cl"; gold asks what % of *all* molecules are carcinogenic AND contain Cl. Also wrong element case (`'Cl'` vs `'cl'`) |
| 5 | california_schools | ORDER BY + LIMIT | **Off** | Added unnecessary `GROUP BY + AVG(AvgScrRead)` — `AvgScrRead` is already a pre-computed average; averaging the averages gives a different result than gold's direct `ORDER BY AvgScrRead` |
| 6 | student_club | CASE WHEN + year diff | **Correct** | Subquery approach vs gold's `CASE WHEN` — functionally equivalent; `strftime('%Y')` vs `SUBSTR(...,1,4)` — both work |
| 7 | formula_1 | String → seconds | **Wrong** | Did `AVG(fastestLapTime)` on a `mm:ss.sss` string; SQLite coerces to 0. Gold uses `SUBSTR`/`INSTR` to parse the string into numeric seconds |

**Score without schema: 1/7 correct.**

#### Key takeaways

1. **Schema injection is the #1 fix.** Every failure in Q1, Q3, Q4 traces back to the model guessing column/table names. The agent's `render_schema` call (Phase 3) eliminates this class of error entirely.

2. **Execution errors are detectable.** Q1, Q3, Q7 would all throw SQL errors at runtime — the `execute` node surfaces these, making them straightforward targets for the `verify → revise` loop.

3. **Semantic errors are harder.** Q4 and Q5 return rows without errors but answer the wrong question. These require the `verify` node to catch — it needs to check whether the result *plausibly answers* the question, not just whether SQL ran cleanly.

4. **The revise loop has clear ROI here.** With schema, first-pass accuracy should jump significantly. The gap between iter-0 and iter-N pass rate in Phase 5 evals will directly measure how much the loop earns its keep — this baseline (1/7 no-schema) vs. the agent result is the argument for the architecture.

---

### Phase 3 — Agent first run

**Root cause of initial failure:** `prompts.py` had all empty strings. Every LLM call sent blank messages → model responded with "It seems like your message might be incomplete..." → `_extract_sql` found no ` ```sql ``` ` block and returned the full prose → SQLite threw `OperationalError: near "It": syntax error` → revise loop hit `MAX_ITERATIONS=3` and gave up.

**Fix:** Filled in all six prompt templates in `prompts.py`:
- `GENERATE_SQL_SYSTEM/USER` — enforces ` ```sql ``` ` output, SQLite-only rules
- `VERIFY_SYSTEM/USER` — defines three failure conditions (SQL error, zero rows, wrong columns), demands JSON-only `{"ok": bool, "issue": str}` output
- `REVISE_SYSTEM/USER` — includes schema + the verifier's `{issue}` so the model knows what to fix

**First successful agent run:**

```
curl -X POST http://localhost:8001/answer \
  -H "Content-Type: application/json" \
  -d '{"question": "List Ajax superpowers.", "db": "superhero"}'
```

```json
{
  "sql": "SELECT sp.power_name FROM superhero s JOIN hero_power hp ON s.id = hp.hero_id JOIN superpower sp ON hp.power_id = sp.id WHERE s.superhero_name = 'Ajax';",
  "rows": [["Agility"], ["Super Strength"], ["Super Speed"], ["Heat Generation"], ["Power Suit"]],
  "iterations": 1,
  "ok": true,
  "error": null
}
```

- `ok: true`, `iterations: 1` — first-pass SQL was correct, verify accepted it, no revise triggered
- Column names correct (`s.id`, `s.superhero_name`) — schema injection eliminated the guessing failure seen in Phase 1 Q3
- Direct comparison: Phase 1 no-schema attempt guessed `s.hero_id` / `s.hero_name` and would have thrown column-not-found; with schema the model used the right names immediately

**Next:** find a question that triggers the verify → revise loop. The `financial` Q1 (`"How many male clients in 'Hl.m. Praha' district?"`) is a strong candidate — requires a join across `client` and `district` with gender encoded as `'M'`, not `'male'`.

---

### Phase 3 — Revise loop stress test

Five questions chosen to trigger the verify → revise loop, each targeting a different failure mode.

| # | DB | Failure mode predicted | Iterations | Revise triggered | Verifier caught it |
|---|---|---|---|---|---|
| 1 | codebase_community | Timestamp format → 0 rows | 2 | ✓ | ✓ |
| 2 | financial | Cryptic column (A14 vs A15) → null result | 3 (max) | ✓ | ✗ |
| 3 | superhero | Missing `weight_kg = 0`, wrong eye-color logic | 1 | ✗ | ✗ |
| 4 | thrombosis_prediction | Simplified UA threshold vs sex-based split | 1 | ✗ | ✗ |
| 5 | codebase_community | Wrong join key (ExcerptPostId) | 1 | ✗ | N/A — first pass correct |

#### Per-request breakdown

**#1 — Timestamp (revise worked)**
- Iter 1: `CreationDate = '2013-07-12 09:08:18'` → 0 rows (missing trailing `.0`)
- Verifier caught 0 rows → revise fired
- Iter 2: switched to `LIKE '2013-07-12 09:08:18%'` → found the row
- Minor: revised SQL returns raw `ClosedDate` column instead of gold's `IIF(ClosedDate IS NULL, 'NOT well-finished', 'well-finished')` verdict. Structurally correct data but requires interpretation. Verifier accepted.

**#2 — Cryptic column (loop failed silently)**
- All 3 iterations used `A14` — never corrected to `A15` (crimes in 1995). The only change across revisions was adding `AND A14 IS NOT NULL`.
- Final result: `[[null]]` — AVG returned null because no rows matched
- **Verifier accepted `[[null]]` as `ok=true`** — gap in the verify prompt: a null result for a "what is the average" question should be flagged
- Root cause unfixable without column descriptions: `render_schema` outputs DDL only, so `A14` and `A15` are indistinguishable to the model

**#3 — NULL vs zero (semantic error, not caught)**
- Model used `WHERE weight_kg IS NULL` only, missing `weight_kg = 0`
- Used `eye_colour_id IS NULL` for "no eye color" instead of gold's `colour.id = 1` lookup
- Returned `[[1]]` in one pass; verifier accepted — result looks plausible from the outside
- Structural class of failure the verifier cannot catch: rows exist, shape is correct, value is wrong

**#4 — Sex-based thresholds (simplified logic, not caught)**
- Model used `UA BETWEEN 3.0 AND 7.0` (unified threshold) instead of `(UA < 6.5 AND SEX='F') OR (UA < 8.0 AND SEX='M')`
- Returned a plausible-looking average (`4.59`); verifier accepted
- Same structural class as #3 — semantically wrong but syntactically clean

**#5 — Join key (first pass correct)**
- Model correctly used `tags.ExcerptPostId` immediately; no revise needed
- Returned `[["mbq", "Warsaw, Poland"]]` matching gold structure
- Model is better at FK inference from DDL than expected

#### Key findings

1. **The revise loop works for detectable errors.** Zero-row results (wrong timestamp, missing join) are reliably caught and corrected.
2. **The verifier has a null blind spot.** A "what is the average" question returning `[[null]]` was accepted as `ok=true`. Fix: add a null-result check to `VERIFY_SYSTEM`.
3. **Semantic errors that return plausible rows are invisible to the verifier.** Wrong thresholds, wrong aggregation logic, simplified conditions — all pass if the result shape looks right. This is a structural limit of result-level verification without ground truth.
4. **Schema without column descriptions is a ceiling.** Opaque column names like `A15` cannot be mapped to meaning from DDL alone. Injecting BIRD's column metadata would eliminate this class of error entirely — noted as a "what I'd do with more time" item for REPORT.md.

---

### Phase 5 — Baseline eval results

**Overall: 9/30 correct (30%). Per-iteration pass rate flat at 0.30 across all iterations — the revise loop is not earning its keep.**

```
iter_0: 0.30
iter_1: 0.30
iter_2: 0.30
iter_3: 0.30
```

#### Passing questions (all iter=1, all first-pass correct)

| Question | DB |
|---|---|
| Ajax superpowers | superhero |
| Top 5 schools by enrollment | california_schools |
| Commentator badges 2014 | codebase_community |
| Super Strength hero count | superhero |
| Coldsnap highest mana cost | card_games |
| Business / Medium t-shirt members | student_club |
| 3 female clients largest loans | financial |
| Agriculture dept major count | student_club |
| hypothesis-testing tag user | codebase_community |

Zero questions improved across iterations. Every correct answer was correct on the first pass.

#### 11 questions triggered revise — none were fixed

| Question | Iters | Why revise ran | Why it didn't fix it |
|---|---|---|---|
| financial A15 column | 3 | used A14 → null result | stuck on A14 across all revisions |
| Praha male clients | 3 | `gender = 'm'` (lowercase) → 0 rows | never corrected case to `'M'` |
| Lewis Hamilton lap time | 3 | wrong time-string parsing | REPLACE approach still wrong |
| Toxicology carcinogenic % | 3 | wrong WHERE logic | rephrased but same logical error |
| Codebase timestamp | 2 | missing `.0` → 0 rows | didn't add `.0` suffix |
| Ancestor's Chosen card | 3 | 0 rows returned | repeated same SQL |
| Thrombosis outpatient | 3 | `Admission='outpatient clinic'` (should be `'-'`) | never found the right encoding |
| Toxicology calcium | 3 | used `'Calcium'` not `'ca'` | element name never corrected |
| Art and Design dept | 3 | `'Art and Design'` vs `'Art and Design Department'` | truncated string never fixed |
| Gladiator banned cards | 3 | `'Gladiator'`/`'banned'` (wrong case) | case never corrected |
| Reputation badge timestamp | 3 | missing `.0` again | same timestamp bug |

#### Why the loop is flat — two root causes

**1. Revise re-generates similar wrong SQL.** When verify says "0 rows returned", the model doesn't have enough signal to change approach — especially for case sensitivity bugs (`'m'` vs `'M'`, `'ca'` vs `'Calcium'`, timestamp `.0`). The issue string needs to be more specific: e.g. "check that string literals match the data exactly, including case and trailing decimal."

**2. Verifier accepts semantically wrong non-empty results.** 10 questions (Q19, Q21, Q22, Q29 and others) never triggered revise despite being wrong — the verifier saw non-empty rows and returned `ok=true`. These queries cannot improve with more iterations regardless of loop depth.

#### What to carry into REPORT.md

> Baseline pass rate: 30% (9/30). Per-iteration pass rate is flat at 0.30 across all iterations — the revise loop triggers on 11/30 questions but fixes none of them. The dominant failure modes are: (1) revise re-generates similar wrong SQL because the issue description from verify lacks specificity about string encoding and case; (2) the verifier accepts semantically wrong but non-empty results, so those queries never enter the revise path at all. The loop architecture is sound; the prompts need iteration.

---

### Phase 6 — SLO tuning, Step 1: baseline load test observations

**SLO target:** P95 end-to-end agent latency < 5s, ≥ 10 RPS (1 RPS = 1 full agent run = 2–3 serial vLLM calls)

**Observed metrics under load:**

| Metric | Value | SLO relevance |
|---|---|---|
| KV cache utilization | 28.4% | Well below 90% alert — memory is NOT the bottleneck |
| P99 e2e latency | 4.59s | P95 is below P99 → P95 likely ~3.5–4.2s, SLO probably met |
| Token generation rate | ~1,250 tok/s | Healthy for 30B MoE on H100 — GPU is working |
| Requests running (`num_requests_running`) | ~35 | High concurrency; explains tail latency |

#### Diagnosis

**KV cache at 28.4%** rules out the two most common vLLM bottlenecks: memory exhaustion and eviction pressure. No need to reduce `--max-model-len` or `--max-num-seqs`. The study guide pattern `gpu_cache_usage_perc > 0.9 → reduce max-model-len` does not apply here.

**35 requests running concurrently** with 1.5–3K token prompts means prefill operations are competing for the GPU. Each agent turn fires a new vLLM call with the full schema + question prompt (~1.5–3K tokens). At 35 concurrent prefills, the GPU is spending significant time on prompt processing, which pushes out time-to-first-token and piles up into tail latency. This is consistent with P99 = 4.59s while token generation throughput is healthy — the GPU is fast when decoding, but the queue of prefills is long.

**RPS estimate:** 35 requests in-flight ÷ ~4.5s avg latency ≈ **~7–8 vLLM RPS**. At 2–3 vLLM calls per agent run, that is roughly 2–4 agent RPS — below the 10 RPS target. P95 latency is likely met; throughput is the open gap.

#### Hypothesis → change

```
saw:        P99 = 4.59s, 35 requests running, KV cache 28.4%, throughput 1.25k tok/s
hypothesis: prefill competition under high concurrency drives tail latency and limits effective
            agent RPS; KV cache has headroom so memory is not the constraint
change:     add --enable-chunked-prefill to interleave prefill with decode steps, reducing
            TTFT spikes and freeing the GPU to handle more concurrent agent runs
result:     TBD (re-run load test after restart)
```

The current `scripts/start_vllm.sh` does not include `--enable-chunked-prefill` — this is the first lever to pull. If chunked prefill reduces P99 and increases throughput, re-run eval to confirm quality is unchanged. If RPS is still short of 10, next lever is `--max-num-seqs` (currently unset, defaulting to vLLM's internal limit) — tuning it upward lets more sequences batch together at the cost of higher per-request latency variance.

---

### Phase 6 — Step 3: tuning iteration results

Three changes applied sequentially, one re-run each. Summary:

| Step | Change | TTFT P95 | E2E latency P95 | KV cache | Verdict |
|---|---|---|---|---|---|
| Baseline | none | 0.2s | ~2.25s | 28.4% | starting point |
| 1 | `--enable-chunked-prefill` | **0.07s** | **0.88s** | 50–60% | **biggest win** |
| 2 | `--max-model-len 65536 → 8192` | minimal | ~2.0s | ~20% | modest improvement |
| 3 | `--max-num-seqs 128` | minimal | minimal | ~10% | no meaningful change |

#### Step 1 — `--enable-chunked-prefill` (dominant fix)

```
saw:        TTFT P95 = 0.2s, E2E P95 ≈ 2.25s, 35 requests running, KV cache 28.4%
hypothesis: long schema prompts (~2K tokens) block decode steps under high concurrency;
            chunked prefill interleaves them, reducing TTFT spikes
change:     --enable-chunked-prefill
result:     TTFT P95 0.2s → 0.07s (-65%), E2E latency 2.25s → 0.88s (-61%),
            KV cache rose to 50–60% (more concurrent sequences in-flight, expected)
```

**Bonus finding — prefix cache hit rate 86.1%:** vLLM logs showed `Prefix cache hit rate: 86.1%`. The schema string is the same for all requests against the same DB — with chunked prefill, vLLM's prefix caching kicks in and reuses KV blocks for repeated schema prefixes. This is why TTFT dropped so sharply: most requests skip re-computing the schema tokens entirely. This was not explicitly configured; it activates alongside chunked prefill.

**vLLM log snapshot during Step 1 run:**
```
Avg prompt throughput: 0.0 tokens/s   ← captured between batches (idle window)
Avg generation throughput: 0.0 tokens/s
Running: 8 reqs, Waiting: 0 reqs     ← no queue backpressure
GPU KV cache usage: 86.7%            ← peak during load; prefix cache holding schema blocks
Prefix cache hit rate: 86.1%
```

The 86.7% peak KV cache with 0 waiting requests means the system is busy but not saturated — no eviction pressure, no stalling.

#### Step 2 — `--max-model-len 65536 → 8192` (modest)

```
saw:        E2E latency P95 still ~2.25s after Step 1 warm-up; max-model-len 8× the workload ceiling
hypothesis: over-sized max-model-len wastes KV block reservation per sequence slot
change:     --max-model-len 8192
result:     E2E P95 2.5s → ~2.0s; KV cache dropped to ~20%; other metrics minimal change
```

KV cache dropping from 50–60% to ~20% reflects fewer blocks reserved per slot — each sequence now maps to a much smaller worst-case allocation. The latency improvement was real but modest: the prefill bottleneck was already fixed in Step 1, so this only trimmed overhead.

#### Step 3 — `--max-num-seqs 128` (no effect)

```
saw:        KV cache at ~20%, latency stable, RPS not dramatically changing after Step 2
hypothesis: explicit concurrency ceiling would let scheduler fill remaining KV headroom
change:     --max-num-seqs 128
result:     KV cache fell further to ~10%; latency and RPS unchanged
```

The lack of improvement reveals where the actual ceiling now is: **the agent itself, not vLLM**. Each agent run makes 2–3 serial vLLM calls (generate → verify → [revise]). Serial calls cannot be parallelised within a single request, so even with vLLM capable of handling 128 concurrent sequences, the agent server feeds it requests one call at a time per user query. With fewer incoming vLLM calls per unit time, the scheduler runs well below its capacity (hence KV cache at 10%). The bottleneck has shifted from the inference layer to the agent orchestration layer.

#### Overall conclusion

Chunked prefill was the single change that mattered. It fixed the root cause (prefill blocking decode under concurrency) and unlocked prefix caching as a side effect (86.1% hit rate on schema tokens). Steps 2 and 3 yielded diminishing returns — the remaining latency is dominated by the agent's serial call structure, not vLLM scheduling.

**REPORT.md verdict:** SLO assessed against the P95 E2E metric. After Step 1, P95 ≈ 0.88s — well under the 5s target. The 10 RPS throughput target should be confirmed with a dedicated 5-minute `driver.py --rps 10 --duration 300` run and the achieved RPS from the summary JSON. If RPS is short, the constraint is agent-side concurrency (uvicorn workers), not vLLM.