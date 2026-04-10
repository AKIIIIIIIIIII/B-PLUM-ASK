#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""把 open-iching 的 ichuan/tuan.json、xiang.json 按 upper/lower 写入 Plum.B/hexagrams.json。"""
from __future__ import annotations

import json
import sys
import urllib.request
from pathlib import Path
from typing import Any, Dict, List, Tuple

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "Plum.B" / "hexagrams.json"
ICHING = "https://raw.githubusercontent.com/john-walks-slow/open-iching/main/iching/iching.json"
TUAN = "https://raw.githubusercontent.com/john-walks-slow/open-iching/main/ichuan/tuan.json"
XIANG = "https://raw.githubusercontent.com/john-walks-slow/open-iching/main/ichuan/xiang.json"

BITS_TO_USER = [0, 4, 6, 2, 7, 3, 5, 1]


def strip_curly_quotes(s: str) -> str:
    return s.replace("\u201c", "").replace("\u201d", "")


def reorder_by_king_wen(items: List[Dict[str, Any]], iching: List[Dict[str, Any]]) -> List[Dict[str, Any]]:
    """按周易卦序排列，并令 id 与卦序一致（1 乾 … 64 未济）。"""
    by_pair = {(int(h["upper"]), int(h["lower"])): h for h in items}
    out: List[Dict[str, Any]] = []
    for e in sorted(iching, key=lambda x: int(x["id"])):
        arr = e.get("array") or []
        if len(arr) != 6:
            continue
        t_lo = arr[0] + 2 * arr[1] + 4 * arr[2]
        t_hi = arr[3] + 2 * arr[4] + 4 * arr[5]
        if not (0 <= t_lo < 8 and 0 <= t_hi < 8):
            continue
        lower = BITS_TO_USER[t_lo]
        upper = BITS_TO_USER[t_hi]
        pair = (upper, lower)
        if pair not in by_pair:
            raise ValueError(f"missing pair {pair} for king id {e.get('id')}")
        row = by_pair[pair]
        row["id"] = int(e["id"])
        out.append(row)
    if len(out) != 64:
        raise ValueError(f"reorder expected 64, got {len(out)}")
    return out


def pair_to_king_id(rows: List[Dict[str, Any]]) -> Dict[Tuple[int, int], int]:
    m: Dict[Tuple[int, int], int] = {}
    for e in rows:
        arr = e.get("array") or []
        if len(arr) != 6:
            continue
        t_lo = arr[0] + 2 * arr[1] + 4 * arr[2]
        t_hi = arr[3] + 2 * arr[4] + 4 * arr[5]
        if not (0 <= t_lo < 8 and 0 <= t_hi < 8):
            continue
        lower = BITS_TO_USER[t_lo]
        upper = BITS_TO_USER[t_hi]
        m[(upper, lower)] = int(e["id"])
    return m


def main() -> None:
    iching = json.loads(urllib.request.urlopen(ICHING, timeout=60).read().decode("utf-8"))
    tuan = json.loads(urllib.request.urlopen(TUAN, timeout=60).read().decode("utf-8"))
    xiang = json.loads(urllib.request.urlopen(XIANG, timeout=60).read().decode("utf-8"))

    pmap = pair_to_king_id(iching)
    if len(pmap) != 64:
        print("expected 64 pairs from iching, got", len(pmap), file=sys.stderr)
        sys.exit(1)

    data: List[Dict[str, Any]] = json.loads(OUT.read_text(encoding="utf-8"))
    for item in data:
        u, lo = int(item["upper"]), int(item["lower"])
        kid = pmap.get((u, lo))
        if kid is None:
            print("no king id for", u, lo, item.get("name"), file=sys.stderr)
            continue
        tk = f"iching__{kid}"
        item["tuan"] = strip_curly_quotes(tuan.get(tk, ""))
        item["daxiang"] = strip_curly_quotes(xiang.get(tk, ""))
        lx = []
        for i in range(1, 7):
            lx.append(strip_curly_quotes(xiang.get(f"iching__{kid}_{i}", "")))
        item["lineXiang"] = lx

    data = reorder_by_king_wen(data, iching)
    OUT.write_text(json.dumps(data, ensure_ascii=False, indent=2), encoding="utf-8")
    print("wrote", OUT, "(周易卦序)")


if __name__ == "__main__":
    main()
