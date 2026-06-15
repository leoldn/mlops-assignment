"""Phase 4 burst: fire 10 agent requests with Langfuse trace tags.

Each request hits /answer with tags={"phase": "baseline"} so traces are
filterable in Langfuse UI during Phase 6 diagnosis.

Run:
    uv run python scripts/phase4_burst.py
"""
from __future__ import annotations

import asyncio
import json

import aiohttp

AGENT_URL = "http://localhost:8001/answer"

# 10 questions across all 7 DBs — mix of easy (likely iter=1) and hard
# (likely to trigger revise) so the Langfuse waterfall shows both shapes.
QUESTIONS = [
    # easy — expect iter=1, clean waterfall
    {"question": "List down Ajax's superpowers.", "db": "superhero"},
    {"question": "How many superheroes have the super power of \"Super Strength\"?", "db": "superhero"},
    {"question": "How many users received commentator badges in 2014?", "db": "codebase_community"},
    {"question": "Please list the name of the cards in the set Coldsnap with the highest converted mana cost.", "db": "card_games"},
    {"question": "Calculate the difference of the total amount spent in all events by the Student_Club in year 2019 and 2020.", "db": "student_club"},
    # harder — expect revise to fire at least once
    {"question": "User No.23853 gave a comment to a post at 9:08:18 on 2013/7/12, was that post well-finished?", "db": "codebase_community"},
    {"question": "What is the average number of crimes committed in 1995 in regions where the number exceeds 4000 and the region has accounts that are opened starting from the year 1997?", "db": "financial"},
    {"question": "Calculate the percentage of carcinogenic molecules which contain the Chlorine element.", "db": "toxicology"},
    {"question": "What is the complete address of the school with the lowest excellence rate? Indicate the Street, City, Zip and State.", "db": "california_schools"},
    {"question": "For all patients with normal uric acid (UA), what is the average UA index based on their latest laboratory examination result?", "db": "thrombosis_prediction"},
]

TAGS = {"phase": "baseline"}


async def fire(session: aiohttp.ClientSession, idx: int, q: dict) -> None:
    payload = {**q, "tags": TAGS}
    print(f"[{idx+1}/10] firing: {q['question'][:60]}...")
    try:
        async with session.post(AGENT_URL, json=payload, timeout=aiohttp.ClientTimeout(total=120)) as resp:
            data = await resp.json()
        iters = data.get("iterations", "?")
        ok = data.get("ok")
        err = data.get("error")
        status = f"ok={ok} iter={iters}"
        if err:
            status += f" err={err[:60]}"
        print(f"[{idx+1}/10] done  {status}")
    except Exception as e:
        print(f"[{idx+1}/10] FAILED: {e}")


async def main() -> None:
    # Fire sequentially so Langfuse traces appear in order and are easy to read.
    # Switch to gather() if you want to stress the concurrency path instead.
    async with aiohttp.ClientSession() as session:
        for idx, q in enumerate(QUESTIONS):
            await fire(session, idx, q)
    print("\nDone. Open Langfuse at http://localhost:3001 and filter by tag phase=baseline.")


if __name__ == "__main__":
    asyncio.run(main())
