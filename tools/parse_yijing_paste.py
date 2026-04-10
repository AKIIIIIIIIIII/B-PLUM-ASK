#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""Parse Plum.B/yijing_paste.txt → update Plum.B/hexagrams.json (卦辞 + 六爻爻辞)."""
from __future__ import annotations

import json
import re
from pathlib import Path
from typing import List, Optional, Tuple

ROOT = Path(__file__).resolve().parents[1]
PASTE = ROOT / "Plum.B" / "yijing_paste.txt"
OUT = ROOT / "Plum.B" / "hexagrams.json"

TR = {
    "乾": 1, "天": 1, "坤": 0, "地": 0, "兑": 2, "泽": 2, "离": 3, "火": 3,
    "震": 4, "雷": 4, "巽": 5, "风": 5, "坎": 6, "水": 6, "艮": 7, "山": 7,
}


def trigram_pair(block: str) -> Optional[Tuple[int, int]]:
    m = re.search(
        r"([乾坤震巽坎离艮兑天泽火雷风水地])上([乾坤震巽坎离艮兑天泽火雷风水地])下",
        block,
    )
    if not m:
        return None
    return TR[m.group(1)], TR[m.group(2)]


def extract_judgment(block: str) -> Optional[str]:
    """卦辞：首行「…：…」，且非序号行、非《传》、非「某上某下」标题行。"""
    for line in block.splitlines():
        line = line.strip()
        if not line or line.startswith("《"):
            continue
        if re.match(r"^\d{1,2}", line):
            continue
        if "上" in line and "下" in line and "：" not in line:
            continue
        if "：" in line or ":" in line:
            if "上" in line and "下" in line:
                continue
            return line
    return None


def extract_line_yao(block: str) -> list[str]:
    """六爻爻辞：到《象》曰或制表符为止。"""
    pat = re.compile(
        r"^(初九|九二|九三|九四|九五|上九|初六|六二|六三|六四|六五|上六)[：:](.+?)(?=\s*《象》|\t|$)",
        re.MULTILINE,
    )
    found = []
    for m in pat.finditer(block):
        name, body = m.group(1), m.group(2).strip()
        found.append(f"{name}：{body}")
    return found


def split_blocks(text: str) -> List[str]:
    text = text.strip()
    cut = text.find("《易经》学习")
    if cut != -1:
        text = text[:cut]
    idx = [m.start() for m in re.finditer(r"(?m)^\d{1,2}(?:\s|卦)", text)]
    blocks = []
    for i, start in enumerate(idx):
        end = idx[i + 1] if i + 1 < len(idx) else len(text)
        blocks.append(text[start:end].strip())
    return blocks


def main() -> None:
    raw = PASTE.read_text(encoding="utf-8")
    if not re.search(r"(?m)^\d{1,2}(?:\s|卦)", raw):
        print("SKIP: yijing_paste.txt 中未检测到「01 乾卦」式正文，未修改 hexagrams.json。")
        return
    blocks = split_blocks(raw)
    by_pair = {}

    for b in blocks:
        pair = trigram_pair(b)
        if pair is None:
            print("skip (no 上/下):", b[:80].replace("\n", " "))
            continue
        j = extract_judgment(b)
        lines = extract_line_yao(b)
        if not j or len(lines) != 6:
            print("bad block", pair, "judgment", j is not None, "lines", len(lines))
            print(b[:200])
            continue
        by_pair[pair] = (j, lines)

    if len(by_pair) != 64:
        print(f"WARNING: parsed {len(by_pair)} hexagrams, expected 64")

    data = json.loads(OUT.read_text(encoding="utf-8"))
    for item in data:
        u, lo = item["upper"], item["lower"]
        key = (u, lo)
        if key not in by_pair:
            print("missing key", key, item.get("name"))
            continue
        j, lines = by_pair[key]
        item["judgment"] = j
        item["lines"] = lines

    OUT.write_text(json.dumps(data, ensure_ascii=False, indent=2), encoding="utf-8")
    print("wrote", OUT, "pairs", len(by_pair))


if __name__ == "__main__":
    main()
