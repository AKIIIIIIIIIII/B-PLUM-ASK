import json
import re
import sys
import time
from html.parser import HTMLParser
from pathlib import Path
from urllib.request import Request, urlopen

try:
    from opencc import OpenCC
except ImportError:
    OpenCC = None


JSON_PATH = Path("Plum.B/hexagrams.json")
BASE_URL = "https://www.eee-learning.com/book/neweee{num:02d}"


class ParagraphParser(HTMLParser):
    def __init__(self) -> None:
        super().__init__()
        self.capture = False
        self.depth = 0
        self.in_p = False
        self.current: list[str] = []
        self.paras: list[str] = []

    def handle_starttag(self, tag, attrs):
        attrs = dict(attrs)
        classes = attrs.get("class", "")
        if not self.capture and tag == "div" and "field--name-body" in classes:
            self.capture = True
            self.depth = 1
            return
        if not self.capture:
            return
        if tag == "div":
            self.depth += 1
        if tag == "p":
            self.in_p = True
            self.current = []

    def handle_endtag(self, tag):
        if not self.capture:
            return
        if tag == "div":
            self.depth -= 1
            if self.depth == 0:
                self.capture = False
                return
        if tag == "p" and self.in_p:
            text = "".join(self.current).replace("\xa0", " ")
            text = re.sub(r"\s+", " ", text).strip()
            if text:
                self.paras.append(text)
            self.in_p = False

    def handle_data(self, data):
        if self.capture and self.in_p:
            self.current.append(data)


def fetch_paragraphs(url: str) -> list[str]:
    request = Request(url, headers={"User-Agent": "Mozilla/5.0"})
    html = urlopen(request, timeout=30).read().decode("utf-8", "ignore")
    parser = ParagraphParser()
    parser.feed(html)
    return parser.paras


def normalize_label(line: str) -> str:
    return line.split("：", 1)[0].replace(":", "：").replace("，", "")


def is_line_start(text: str, labels: list[str]) -> bool:
    return any(text.startswith(label + "，") or text.startswith(label + ",") for label in labels)


def extract_summaries(paragraphs: list[str], labels: list[str]) -> list[str]:
    all_labels = labels + ["用九", "用六"]
    skip_prefixes = (
        "《",
        "繫辭：",
        "經文當作",
        "子曰：",
        "文言曰：",
    )
    summaries: list[str] = []

    for label in labels:
        matches = [
            i
            for i, para in enumerate(paragraphs)
            if para.startswith(label + "，") or para.startswith(label + ",")
        ]
        if not matches:
            raise ValueError(f"Could not find line paragraph for {label}")
        line_index = matches[-1]

        summary = None
        for para in paragraphs[line_index + 1 :]:
            if is_line_start(para, all_labels):
                break
            if para.startswith(skip_prefixes):
                continue
            if "（圖：" in para or "(圖：" in para:
                continue
            summary = para
            break

        if not summary:
            raise ValueError(f"Could not extract summary for {label}")
        summaries.append(summary)

    return summaries


def extract_judgment_summary(paragraphs: list[str], first_line_label: str) -> str:
    matches = [
        i
        for i, para in enumerate(paragraphs)
        if para.startswith(first_line_label + "，") or para.startswith(first_line_label + ",")
    ]
    if not matches:
        raise ValueError(f"Could not find first line paragraph for {first_line_label}")
    first_line_index = matches[-1]

    start_index = None
    for i in range(first_line_index - 1):
        if paragraphs[i + 1].startswith("《彖》曰"):
            start_index = i + 1
            break

    if start_index is None:
        raise ValueError("Could not locate judgment quote block")

    for para in paragraphs[start_index + 1 : first_line_index]:
        if para.startswith(("《", "繫辭：", "文言曰：")):
            continue
        if "（圖：" in para or "(圖：" in para:
            continue
        return para

    raise ValueError("Could not extract judgment summary")


def simplify_text(value):
    if OpenCC is None:
        return value

    converter = OpenCC("t2s")
    if isinstance(value, str):
        return converter.convert(value)
    if isinstance(value, list):
        return [converter.convert(item) for item in value]
    return value


def main() -> int:
    debug_id = int(sys.argv[1]) if len(sys.argv) > 1 else None
    data = json.loads(JSON_PATH.read_text(encoding="utf-8"))

    for item in data:
        if debug_id is not None and item["id"] != debug_id:
            continue
        labels = [normalize_label(line) for line in item["lines"]]
        url = BASE_URL.format(num=item["id"])
        paragraphs = fetch_paragraphs(url)
        try:
            item["judgmentSummary"] = extract_judgment_summary(paragraphs, labels[0])
            item["lineSummary"] = extract_summaries(paragraphs, labels)
        except Exception as exc:
            print(f"Failed on id={item['id']} name={item['name']} url={url}", file=sys.stderr)
            print(exc, file=sys.stderr)
            for index, para in enumerate(paragraphs):
                print(f"{index}: {para}", file=sys.stderr)
            return 1
        item["judgmentSummary"] = simplify_text(item["judgmentSummary"])
        item["lineSummary"] = simplify_text(item["lineSummary"])
        time.sleep(0.15)

    if debug_id is not None:
        print(json.dumps(
            {
                "judgmentSummary": item["judgmentSummary"],
                "lineSummary": item["lineSummary"],
            },
            ensure_ascii=False,
            indent=2,
        ))
        return 0

    JSON_PATH.write_text(json.dumps(data, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    print(f"Updated {len(data)} hexagrams.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
