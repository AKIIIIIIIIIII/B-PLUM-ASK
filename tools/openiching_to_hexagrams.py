#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""Fetch open-iching JSON and write Plum.B/hexagrams.json (upper/lower 与 App 一致)."""
from __future__ import annotations

import json
import sys
import urllib.request
from pathlib import Path
from typing import Any, Dict, List, Optional

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "Plum.B" / "hexagrams.json"
URL = "https://raw.githubusercontent.com/john-walks-slow/open-iching/main/iching/iching.json"

BITS_TO_USER = [0, 4, 6, 2, 7, 3, 5, 1]
TRIGRAM_CHARS = ["地", "天", "泽", "火", "雷", "风", "水", "山"]


def pure_name(upper: int, lower: int, short: str) -> str:
    if upper != lower:
        return TRIGRAM_CHARS[upper] + TRIGRAM_CHARS[lower] + short
    key = (upper, short)
    return {
        (0, "坤"): "坤为地",
        (1, "乾"): "乾为天",
        (2, "兑"): "兑为泽",
        (3, "离"): "离为火",
        (3, "離"): "离为火",
        (4, "震"): "震为雷",
        (5, "巽"): "巽为风",
        (6, "坎"): "坎为水",
        (7, "艮"): "艮为山",
    }.get(key, short)


def convert(entry: Dict[str, Any]) -> Optional[Dict[str, Any]]:
    arr = entry.get("array") or []
    if len(arr) != 6:
        return None
    t_lo = arr[0] + 2 * arr[1] + 4 * arr[2]
    t_hi = arr[3] + 2 * arr[4] + 4 * arr[5]
    if not (0 <= t_lo < 8 and 0 <= t_hi < 8):
        return None
    lower = BITS_TO_USER[t_lo]
    upper = BITS_TO_USER[t_hi]
    short = entry["name"].strip()
    name = pure_name(upper, lower, short)
    lines_raw: List[Dict[str, Any]] = [ln for ln in entry["lines"] if 1 <= ln.get("id", 0) <= 6]
    lines_raw.sort(key=lambda x: x["id"])
    if len(lines_raw) != 6:
        return None
    lines = [f'{ln["name"]}：{ln["scripture"].strip()}' for ln in lines_raw]
    judgment = entry.get("scripture", "").strip()
    return {
        "id": entry["id"],
        "upper": upper,
        "lower": lower,
        "name": name,
        "judgment": judgment,
        "lines": lines,
    }


def main() -> None:
    data = urllib.request.urlopen(URL, timeout=60).read()
    rows = json.loads(data.decode("utf-8"))
    by_pair = {}
    for e in rows:
        h = convert(e)
        if h:
            by_pair[(h["upper"], h["lower"])] = h
    if len(by_pair) != 64:
        print("expected 64, got", len(by_pair), file=sys.stderr)
        sys.exit(1)
    # 周易卦序（与 open-iching / 知乎一致）：乾 id=1 … 未济 id=64
    out_list = []
    for e in sorted(rows, key=lambda x: int(x["id"])):
        h = convert(e)
        if h is None:
            print("convert failed for king id", e.get("id"), file=sys.stderr)
            sys.exit(1)
        out_list.append(h)
    if len(out_list) != 64:
        print("expected 64 after sort, got", len(out_list), file=sys.stderr)
        sys.exit(1)
    OUT.write_text(json.dumps(out_list, ensure_ascii=False, indent=2), encoding="utf-8")
    print("wrote", OUT)


if __name__ == "__main__":
    main()
