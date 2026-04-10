#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""将 Plum.B/hexagrams.json 按《周易》卦序重排：id 1 乾为天 … id 64 火水未济（与知乎 / open-iching 一致）。"""
from __future__ import annotations

import json
import sys
import urllib.request
from pathlib import Path
from typing import Any, Dict, List, Tuple

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "Plum.B" / "hexagrams.json"
ICHING = "https://raw.githubusercontent.com/john-walks-slow/open-iching/main/iching/iching.json"

BITS_TO_USER = [0, 4, 6, 2, 7, 3, 5, 1]


def pair_for_entry(e: Dict[str, Any]) -> Tuple[int, int]:
    arr = e.get("array") or []
    if len(arr) != 6:
        raise ValueError("bad array")
    t_lo = arr[0] + 2 * arr[1] + 4 * arr[2]
    t_hi = arr[3] + 2 * arr[4] + 4 * arr[5]
    if not (0 <= t_lo < 8 and 0 <= t_hi < 8):
        raise ValueError("trigram range")
    lower = BITS_TO_USER[t_lo]
    upper = BITS_TO_USER[t_hi]
    return upper, lower


def reorder(items: List[Dict[str, Any]], iching: List[Dict[str, Any]]) -> List[Dict[str, Any]]:
    by_pair = {(int(h["upper"]), int(h["lower"])): h for h in items}
    if len(by_pair) != 64:
        print("expected 64 unique upper/lower, got", len(by_pair), file=sys.stderr)
        sys.exit(1)
    out: List[Dict[str, Any]] = []
    for e in sorted(iching, key=lambda x: int(x["id"])):
        try:
            u, lo = pair_for_entry(e)
        except ValueError:
            continue
        pair = (u, lo)
        if pair not in by_pair:
            print("missing pair", pair, "for king id", e.get("id"), file=sys.stderr)
            sys.exit(1)
        row = by_pair[pair]
        row["id"] = int(e["id"])
        out.append(row)
    if len(out) != 64:
        print("expected 64 rows after reorder, got", len(out), file=sys.stderr)
        sys.exit(1)
    return out


def main() -> None:
    iching = json.loads(urllib.request.urlopen(ICHING, timeout=60).read().decode("utf-8"))
    data = json.loads(OUT.read_text(encoding="utf-8"))
    ordered = reorder(data, iching)
    OUT.write_text(json.dumps(ordered, ensure_ascii=False, indent=2), encoding="utf-8")
    print("wrote", OUT, "order: id 1 =", ordered[0].get("name"), "id 64 =", ordered[-1].get("name"))


if __name__ == "__main__":
    main()
