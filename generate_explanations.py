#!/usr/bin/env python3
"""
Optional: batch-generate long AI explanations for all parsed questions.

Reads ~/Library/Application Support/TossUp/questions_cache.json (after running the app once)
and writes TossUp/Resources/explanations.json for bundling.

Requires: pip install anthropic   (or set OPENAI_API_KEY for OpenAI)

Usage:
  export ANTHROPIC_API_KEY=sk-...
  python3 generate_explanations.py --limit 50   # test run
  python3 generate_explanations.py              # all questions
"""

from __future__ import annotations

import argparse
import json
import os
import sys
import time
from pathlib import Path

ROOT = Path(__file__).resolve().parent
CACHE = Path.home() / "Library/Application Support/TossUp/questions_cache.json"
OUT = ROOT / "TossUp/Resources/explanations.json"

PROMPT = """You are a Science Bowl coach for a middle-school student.
Write a clear, friendly 3-4 paragraph explanation for this question.
Include: what concept is tested, why the correct answer is right, why common wrong answers fail, and one memory tip.
Use markdown **bold** for key terms. Do not repeat the question verbatim.

Question ({subject}, {qtype}):
{question}
{choices}
Correct answer: {answer}
"""


def load_questions() -> list[dict]:
    if not CACHE.exists():
        print(f"Cache not found: {CACHE}", file=sys.stderr)
        print("Run the app once to parse PDFs, then retry.", file=sys.stderr)
        sys.exit(1)
    data = json.loads(CACHE.read_text())
    return data.get("questions", [])


def cache_key(q: dict) -> str:
    return f"{q['sourcePDF']}|{q['questionText']}"


def call_claude(prompt: str) -> str:
    import anthropic

    client = anthropic.Anthropic()
    msg = client.messages.create(
        model="claude-sonnet-4-20250514",
        max_tokens=800,
        messages=[{"role": "user", "content": prompt}],
    )
    return msg.content[0].text.strip()


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--limit", type=int, default=0, help="Max questions (0 = all)")
    parser.add_argument("--resume", action="store_true", help="Skip keys already in output file")
    args = parser.parse_args()

    questions = load_questions()
    if args.limit:
        questions = questions[: args.limit]

    existing: dict[str, str] = {}
    if args.resume and OUT.exists():
        existing = {e["key"]: e["text"] for e in json.loads(OUT.read_text()).get("explanations", [])}

    entries = [{"key": k, "text": t} for k, t in existing.items()]
    done_keys = set(existing)

    for i, q in enumerate(questions):
        key = cache_key(q)
        if key in done_keys:
            continue

        choices = q.get("choices") or []
        choices_text = "\n".join(choices) if choices else ""
        prompt = PROMPT.format(
            subject=q.get("subject", ""),
            qtype=q.get("type", ""),
            question=q["questionText"],
            choices=choices_text,
            answer=q["correctAnswer"],
        )

        try:
            text = call_claude(prompt)
        except Exception as e:
            print(f"Failed {key[:60]}...: {e}", file=sys.stderr)
            continue

        entries.append({"key": key, "text": text})
        done_keys.add(key)
        print(f"[{i + 1}/{len(questions)}] {key[:70]}...")

        OUT.parent.mkdir(parents=True, exist_ok=True)
        OUT.write_text(json.dumps({"explanations": entries}, indent=2))
        time.sleep(0.5)

    print(f"Wrote {len(entries)} explanations to {OUT}")
    print("Add explanations.json to Xcode Resources, then rebuild.")


if __name__ == "__main__":
    main()
