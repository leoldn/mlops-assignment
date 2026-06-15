import asyncio, aiohttp, json
from pathlib import Path

QUESTIONS = [json.loads(l)["question"] for l in
             Path("evals/eval_set.jsonl").read_text().splitlines()]

async def fire(session, q):
    payload = {
        "model": "Qwen/Qwen3-30B-A3B-Instruct-2507",
        "messages": [{"role": "user", "content": f"Write SQLite SQL for: {q}"}],
        "max_tokens": 150,
    }
    async with session.post("http://localhost:8000/v1/chat/completions", json=payload) as r:
        await r.read()

async def main(concurrency=8, rounds=5):
    async with aiohttp.ClientSession() as session:
        for _ in range(rounds):
            await asyncio.gather(*[fire(session, q) for q in QUESTIONS[:concurrency]])
            print(f"round done")

asyncio.run(main())
