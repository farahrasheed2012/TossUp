#!/usr/bin/env python3
"""Normalize bundled question JSON and split into Resources/*.json files."""

from __future__ import annotations

import json
import re
import sys
from collections import defaultdict
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
INCOMING = ROOT / "Scripts" / "incoming_questions.json"
RESOURCES = ROOT / "TossUp" / "Resources"

CHOICE_FIX = re.compile(r'^([WXYZ])"\)')


def fix_choices(choices: list[str] | None) -> list[str] | None:
    if not choices:
        return choices
    return [CHOICE_FIX.sub(r"\1)", choice) for choice in choices]


def normalize(record: dict) -> dict:
    record = dict(record)
    record["choices"] = fix_choices(record.get("choices"))
    return record


def should_skip_duplicate(existing: dict, incoming: dict) -> bool:
    """Drop the biology duplicate of chem-reactions-006."""
    if existing.get("id") != incoming.get("id"):
        return False
    if incoming.get("id") == "chem-reactions-006" and incoming.get("subject") == "biology":
        return True
    return False


CHOICE_FIX = re.compile(r'^([WXYZ])"\)')
JSON_CHOICE_FIX = re.compile(r'"([WXYZ])"\)([^"]*)"')


def repair_json_text(text: str) -> str:
    """Fix Claude typo: \"X\") Label\" -> \"X) Label\" inside choices arrays."""
    return JSON_CHOICE_FIX.sub(r'"\1)\2"', text)


def load_records() -> list[dict]:
    raw = INCOMING.read_text(encoding="utf-8")
    data = json.loads(repair_json_text(raw))
    by_id: dict[str, dict] = {}
    for raw in data:
        record = normalize(raw)
        rid = record.get("id")
        if not rid:
            continue
        if rid in by_id and should_skip_duplicate(by_id[rid], record):
            continue
        by_id[rid] = record
    return list(by_id.values())


def outfile_name(subject: str, source_pdf: str) -> str:
    if subject == "biology":
        return "bio_bundled_questions.json"
    if subject == "chemistry":
        return "chem_bundled_questions.json"
    if subject == "math":
        return "math_bundled_questions.json"
    return f"{subject}_bundled_questions.json"


def main() -> int:
    if not INCOMING.exists():
        print(f"Missing {INCOMING}", file=sys.stderr)
        return 1

    records = load_records()
    buckets: dict[str, list[dict]] = defaultdict(list)
    for record in records:
        key = record.get("subject", "unknown")
        buckets[key].append(record)

    RESOURCES.mkdir(parents=True, exist_ok=True)
    for subject, items in sorted(buckets.items()):
        items.sort(key=lambda r: r.get("id", ""))
        name = outfile_name(subject, items[0].get("sourcePDF", ""))
        path = RESOURCES / name
        path.write_text(json.dumps(items, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")
        print(f"Wrote {len(items)} questions -> {path.name}")

    print(f"Total: {len(records)} questions")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
