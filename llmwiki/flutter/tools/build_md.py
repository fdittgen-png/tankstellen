#!/usr/bin/env python3
"""Generate clean Markdown twins of every wiki page, per the llms.txt convention.

The llms.txt spec asks that each HTML page also be available as Markdown at the
same URL with `.md` appended. Hand-maintained twins diverge, so this derives
them from the HTML instead. Standard library only.

    python3 tools/build_md.py            # write <page>.html.md next to each page
    python3 tools/build_md.py --full     # also write llms-full.txt
    python3 tools/build_md.py --check    # exit 1 if any twin is missing/stale

Preserved: headings, paragraphs, lists, tables, fenced code (language from
data-lang), links, inline code, emphasis, and callouts (as blockquotes tagged
with the callout kind). Dropped: the navigation shell, scripts, styles and the
JSON-LD block.

Each <section>'s chunk metadata is emitted as an HTML comment so a retrieval
pipeline can read it out of the Markdown.
"""

from __future__ import annotations

import argparse
import html
import re
import sys
from html.parser import HTMLParser
from pathlib import Path

WIKI = Path(__file__).resolve().parent.parent

SKIP = {"script", "style", "head", "nav"}
VOID = {"br", "img", "meta", "link", "hr", "input", "source"}
CALLOUTS = ("rule", "trap", "why", "check")
HEADINGS = {"h1": "#", "h2": "##", "h3": "###", "h4": "####"}


class Sink:
    """A text accumulator. Blocks go to `blocks`; inline text to `line`."""

    def __init__(self) -> None:
        self.blocks: list[str] = []
        self.line: list[str] = []

    def add(self, text: str) -> None:
        self.line.append(text)

    def flush(self, prefix: str = "") -> None:
        text = "".join(self.line)
        self.line.clear()
        text = re.sub(r"[ \t]+", " ", text).strip()
        if text:
            self.blocks.append(prefix + text)

    def push(self, block: str) -> None:
        self.flush()
        if block:
            self.blocks.append(block)


class PageParser(HTMLParser):
    def __init__(self) -> None:
        super().__init__(convert_charrefs=True)
        self.doc = Sink()
        self.cell: list[str] | None = None      # active table cell text
        self.row: list[str] | None = None
        self.tables: list[list[list[str]]] = []
        self.list_stack: list[str] = []
        self.list_items: list[str] = []          # buffered items of current list
        self.skip_depth = 0
        self.in_article = False
        self.in_pre = False
        self.pre_lang = ""
        self.pre_buf: list[str] = []
        self.in_title = False
        self.title = ""
        self.prefix: str | None = None           # block prefix pending for next flush
        self.span_close: list[str] = []
        self.href = ""
        self.callout = 0        # >0 while inside a callout: blockquote the body
        self.div_depth = 0      # to know which </div> closes the callout
        self.callout_at = -1
        self.drop = 0           # >0 while inside an element whose text we discard

    # -- text routing ---------------------------------------------------

    def _add(self, text: str) -> None:
        if self.drop:
            return
        if self.cell is not None:
            self.cell.append(text)
        else:
            self.doc.add(text)

    def _q(self, block: str) -> str:
        """Blockquote a block when it is inside a callout."""
        if not self.callout:
            return block
        return "\n".join("> " + ln if ln.strip() else ">" for ln in block.split("\n"))

    def _flush(self) -> None:
        if self.cell is not None:
            return
        if self.list_stack and self.doc.line:
            # buffer list items so the list renders as one block
            text = re.sub(r"[ \t]+", " ", "".join(self.doc.line)).strip()
            self.doc.line.clear()
            if text:
                self.list_items.append((self.prefix or "- ") + text)
            self.prefix = None
            return
        text = "".join(self.doc.line)
        self.doc.line.clear()
        text = re.sub(r"[ \t]+", " ", text).strip()
        self.prefix, pre = None, (self.prefix or "")
        if text:
            self.doc.blocks.append(self._q(pre + text))

    def _push(self, block: str) -> None:
        self._flush()
        if self.cell is None and block:
            self.doc.blocks.append(self._q(block))

    # -- tags -----------------------------------------------------------

    def handle_starttag(self, tag, attrs):  # noqa: C901
        a = dict(attrs)
        cls = a.get("class", "").split()

        if tag == "title":
            self.in_title = True
            return
        if tag in SKIP:
            self.skip_depth += 1
            return
        if self.skip_depth:
            return
        if tag == "article":
            self.in_article = True
            return
        if not self.in_article:
            return

        if self.in_pre:
            return

        if tag == "section":
            self._flush()
            cid, tags = a.get("data-chunk-id"), a.get("data-tags")
            if cid:
                meta = f"<!-- chunk: {cid}"
                if tags:
                    meta += f" | tags: {tags}"
                self._push(meta + " -->")
        elif tag in HEADINGS:
            self._flush()
            self.prefix = HEADINGS[tag] + " "
        elif tag == "p":
            self._flush()
            if "lede" in cls:
                self.prefix = "> "
        elif tag == "span":
            if "kicker" in cls:
                self._flush()
                self._add("**")
                self.span_close.append("**")
            elif "tag" in cls:
                # The callout marker already carries the kind — drop the label.
                self.drop += 1
                self.span_close.append("\x00drop")
            elif "pill" in cls:
                self._add("`")
                self.span_close.append("`")
            else:
                self.span_close.append("")
        elif tag == "div":
            self.div_depth += 1
            if "callout" in cls:
                self._flush()
                kind = next((k for k in CALLOUTS if k in cls), "note")
                self.callout = 1
                self.callout_at = self.div_depth
                self._push(f"**[{kind.upper()}]**")
        elif tag == "pre":
            self._flush()
            self.in_pre = True
            self.pre_lang = a.get("data-lang", "")
            self.pre_buf = []
        elif tag == "code":
            self._add("`")
        elif tag in ("strong", "b"):
            self._add("**")
        elif tag in ("em", "i"):
            self._add("*")
        elif tag == "a":
            self._add("[")
            self.href = a.get("href", "")
        elif tag in ("ul", "ol"):
            self._flush()
            self.list_stack.append(tag)
        elif tag == "li":
            self._flush()
            depth = max(0, len(self.list_stack) - 1)
            marker = "- " if (self.list_stack or ["ul"])[-1] == "ul" else "1. "
            self.prefix = "  " * depth + marker
        elif tag == "table":
            self._flush()
            self.tables.append([])
        elif tag == "tr" and self.tables:
            self.row = []
        elif tag in ("td", "th") and self.row is not None:
            self.cell = []
        elif tag == "hr":
            self._push("---")
        elif tag == "br":
            self._add("  \n")

    def handle_endtag(self, tag):  # noqa: C901
        if tag == "title":
            self.in_title = False
            return
        if tag in SKIP:
            self.skip_depth = max(0, self.skip_depth - 1)
            return
        if self.skip_depth or not self.in_article:
            return

        if tag == "pre":
            code = "".join(self.pre_buf).strip("\n")
            self.pre_buf = []
            self.in_pre = False
            fence = f"```{self.pre_lang}" if self.pre_lang else "```"
            self._push(f"{fence}\n{code}\n```")
            self.pre_lang = ""
            return
        if self.in_pre:
            return

        if tag == "article":
            self._flush()
            self.in_article = False
        elif tag in HEADINGS or tag in ("p", "li"):
            self._flush()
        elif tag == "span":
            if self.span_close:
                closer = self.span_close.pop()
                if closer == "\x00drop":
                    self.drop = max(0, self.drop - 1)
                else:
                    self._add(closer)
        elif tag == "div":
            self._flush()
            if self.callout and self.div_depth == self.callout_at:
                self.callout = 0
                self.callout_at = -1
            self.div_depth = max(0, self.div_depth - 1)
        elif tag == "code":
            self._add("`")
        elif tag in ("strong", "b"):
            self._add("**")
        elif tag in ("em", "i"):
            self._add("*")
        elif tag == "a":
            self._add(f"]({self.href})")
        elif tag in ("ul", "ol"):
            self._flush()
            if self.list_stack:
                self.list_stack.pop()
            if not self.list_stack and self.list_items:
                self.doc.push("\n".join(self.list_items))
                self.list_items = []
        elif tag in ("td", "th") and self.cell is not None:
            text = re.sub(r"\s+", " ", "".join(self.cell)).strip()
            self.row.append(text or " ")  # type: ignore[union-attr]
            self.cell = None
        elif tag == "tr" and self.row is not None:
            if self.tables and self.row:
                self.tables[-1].append(self.row)
            self.row = None
        elif tag == "table" and self.tables:
            self.doc.push(render_table(self.tables.pop()))
        elif tag == "section":
            self._flush()

    def handle_data(self, data):
        if self.in_title:
            self.title += data
            return
        if self.skip_depth or not self.in_article:
            return
        if self.in_pre:
            self.pre_buf.append(data)
            return
        text = re.sub(r"\s+", " ", data)
        if not text.strip():
            # collapse inter-tag whitespace to a single separator
            sink = self.cell if self.cell is not None else self.doc.line
            if sink and not str(sink[-1]).endswith((" ", "\n")):
                self._add(" ")
            return
        self._add(text)

    def markdown(self) -> str:
        self._flush()
        body = "\n\n".join(b.strip() for b in self.doc.blocks if b.strip())
        # NB: no global whitespace collapse here — text blocks are already
        # normalised in _flush, and code blocks must stay verbatim (a global
        # rule would eat the indentation of fenced YAML inside a callout).
        body = re.sub(r"\n{3,}", "\n\n", body)
        body = re.sub(r"[ \t]+\n", "\n", body)
        return body.strip() + "\n"


def render_table(rows: list[list[str]]) -> str:
    if not rows:
        return ""
    width = max(len(r) for r in rows)
    out: list[str] = []
    for i, row in enumerate(rows):
        cells = [c.replace("|", "\\|") or " " for c in row] + [" "] * (width - len(row))
        out.append("| " + " | ".join(cells) + " |")
        if i == 0:
            out.append("|" + "|".join([" --- "] * width) + "|")
    return "\n".join(out)


def convert(path: Path) -> tuple[str, str]:
    p = PageParser()
    p.feed(path.read_text(encoding="utf-8"))
    return html.unescape(p.title).strip(), p.markdown()


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--full", action="store_true", help="also write llms-full.txt")
    ap.add_argument("--check", action="store_true", help="fail if a twin is stale")
    args = ap.parse_args()

    pages = sorted(WIKI.glob("*.html"))
    if not pages:
        print(f"no .html pages found in {WIKI}", file=sys.stderr)
        return 2

    stale: list[str] = []
    parts: list[str] = []

    for page in pages:
        title, md = convert(page)
        target = page.with_suffix(".html.md")
        if args.check:
            if not target.exists() or target.read_text(encoding="utf-8") != md:
                stale.append(target.name)
        else:
            target.write_text(md, encoding="utf-8")
            print(f"wrote {target.name}  ({len(md):,} chars)")
        parts.append(f"<!-- source: {page.name} | title: {title} -->\n\n{md}")

    if args.check:
        if stale:
            print("stale or missing twins:", ", ".join(stale), file=sys.stderr)
            print("run: python3 tools/build_md.py", file=sys.stderr)
            return 1
        print(f"all {len(pages)} Markdown twins are current")
        return 0

    if args.full:
        header = (WIKI / "llms.txt").read_text(encoding="utf-8")
        out = WIKI / "llms-full.txt"
        out.write_text(header + "\n\n---\n\n" + "\n\n---\n\n".join(parts), encoding="utf-8")
        print(f"wrote {out.name}  ({out.stat().st_size:,} bytes)")

    return 0


if __name__ == "__main__":
    raise SystemExit(main())
