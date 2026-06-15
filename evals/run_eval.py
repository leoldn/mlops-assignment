"""Eval runner using execution accuracy.

Reads evals/eval_set.jsonl, calls the agent at AGENT_URL on each question,
then compares the agent's SQL output to the gold SQL by *executed rows*
(canonicalized: sorted, stringified, None-coerced to empty).

Helpers (run_sql / canonicalize / matches) are provided. You implement
eval_one() and summarize().

Run:
    uv run python evals/run_eval.py --out results/eval_baseline.json
"""
from __future__ import annotations

import argparse
import json
import sqlite3
import time
from pathlib import Path

import httpx

ROOT = Path(__file__).resolve().parent.parent
DEFAULT_EVAL_FILE = ROOT / "evals" / "eval_set.jsonl"
DEFAULT_OUT_FILE = ROOT / "results" / "eval_baseline.json"
DB_DIR = ROOT / "data" / "bird"
AGENT_URL_DEFAULT = "http://localhost:8001/answer"


# ---------- Helpers (provided) -----------------------------------------

def run_sql(db_id: str, sql: str, timeout: float = 5.0) -> tuple[bool, list[tuple] | None, str | None]:
    """Run sql against db_id in read-only mode. Returns (ok, rows, error)."""
    path = DB_DIR / f"{db_id}.sqlite"
    try:
        with sqlite3.connect(f"file:{path}?mode=ro", uri=True, timeout=timeout) as conn:
            cur = conn.execute(sql)
            rows = cur.fetchall()
            return True, rows, None
    except Exception as e:  # noqa: BLE001
        return False, None, f"{type(e).__name__}: {e}"


def canonicalize(rows: list[tuple] | None) -> list[tuple] | None:
    """Sort rows; coerce cells to str; None -> ''."""
    if rows is None:
        return None
    return sorted(tuple("" if c is None else str(c) for c in row) for row in rows)


def matches(gold_rows: list[tuple] | None, pred_rows: list[tuple] | None) -> bool:
    if gold_rows is None or pred_rows is None:
        return False
    return canonicalize(gold_rows) == canonicalize(pred_rows)


# ---------- Implement these (Phase 5) ----------------------------------

def eval_one(question: dict, agent_url: str) -> dict:
    """Score one question. Return a dict capturing per-iteration correctness."""    
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
    """Aggregate per-question results.

    Per-iteration carry-forward: if the agent terminated at iteration j < k
    (verify said ok at j, or it hit MAX_ITERATIONS at j < k), treat the
    question's iteration-k result as identical to its iteration-j result.
    The agent stopped emitting; whatever it had at termination is what
    would have been served had we polled at iteration k.
    """
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


# ---------- Main (provided) --------------------------------------------

def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--eval-set", type=Path, default=DEFAULT_EVAL_FILE)
    parser.add_argument("--out", type=Path, default=DEFAULT_OUT_FILE)
    parser.add_argument("--agent-url", default=AGENT_URL_DEFAULT)
    args = parser.parse_args()

    questions = [json.loads(line) for line in args.eval_set.read_text().splitlines() if line.strip()]
    print(f"Loaded {len(questions)} eval questions from {args.eval_set}")

    results: list[dict] = []
    t0 = time.monotonic()
    for i, q in enumerate(questions, 1):
        print(f"[{i}/{len(questions)}] {q['db_id']}: {q['question'][:60]}...", flush=True)
        results.append(eval_one(q, args.agent_url))
    elapsed = time.monotonic() - t0

    summary = summarize(results)
    out = {
        "summary": summary,
        "wall_clock_seconds": elapsed,
        "results": results,
    }
    args.out.parent.mkdir(parents=True, exist_ok=True)
    args.out.write_text(json.dumps(out, indent=2))
    print(f"Wrote {args.out}")
    print(json.dumps(summary, indent=2))


if __name__ == "__main__":
    main()
