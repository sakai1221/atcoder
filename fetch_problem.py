#!/usr/bin/env python3
"""AtCoder の問題ページから問題文を取り出して Markdown で保存する。

使い方:
    python3 fetch_problem.py <task_url> <output.md>
    python3 fetch_problem.py --check <task_url>   # 問題ページがあるかだけ調べる (new_contest.sh 用)
        終了コード: 0 = ある / 2 = ない (404) / 3 = ログインが必要 / 1 = 通信エラーなど

日本語の問題文 (span.lang-ja) を優先し、無ければ英語 (span.lang-en) を使う。
<var> は $...$ (VSCode の Markdown プレビューで数式表示) に変換する。
oj の cookie.jar があればそれを使う(コンテスト中など、ログインが要るページ用)。
"""
import html
import os
import re
import sys
import urllib.request
from html.parser import HTMLParser
from http.cookiejar import LWPCookieJar

OJ_JAR = os.path.expanduser("~/.local/share/online-judge-tools/cookie.jar")


def fetch(url):
    jar = LWPCookieJar()
    if os.path.exists(OJ_JAR):
        try:
            jar.load(OJ_JAR, ignore_discard=True)
        except Exception:
            pass
    opener = urllib.request.build_opener(urllib.request.HTTPCookieProcessor(jar))
    req = urllib.request.Request(url, headers={"User-Agent": "Mozilla/5.0"})
    with opener.open(req, timeout=20) as res:
        return res.read().decode("utf-8")


class StatementParser(HTMLParser):
    """span.lang-<lang> の中身を Markdown に変換する。"""

    def __init__(self, lang):
        super().__init__()
        self.lang = lang
        self.out = []
        self.capturing = False
        self.span_depth = 0
        self.in_pre = False
        self.in_var = False
        self.lists = []  # "ul" / "ol" のスタック
        self.ol_counters = []
        self.row_count = 0
        self.cells = 0

    def emit(self, s):
        self.out.append(s)

    def handle_starttag(self, tag, attrs):
        a = dict(attrs)
        if not self.capturing:
            if tag == "span" and f"lang-{self.lang}" in (a.get("class") or "").split():
                self.capturing = True
                self.span_depth = 1
            return
        if tag == "span":
            self.span_depth += 1
        elif tag in ("h1", "h2", "h3", "h4"):
            self.emit("\n\n" + "#" * int(tag[1]) + " ")
        elif tag in ("p", "div", "section"):
            self.emit("\n\n")
        elif tag == "pre":
            self.in_pre = True
            self.emit("\n\n```\n")
        elif tag == "var":
            self.in_var = True
            if not self.in_pre:
                self.emit("$")
        elif tag in ("ul", "ol"):
            self.lists.append(tag)
            self.ol_counters.append(0)
            self.emit("\n")
        elif tag == "li":
            indent = "  " * (len(self.lists) - 1)
            if self.lists and self.lists[-1] == "ol":
                self.ol_counters[-1] += 1
                self.emit(f"\n{indent}{self.ol_counters[-1]}. ")
            else:
                self.emit(f"\n{indent}- ")
        elif tag == "br":
            self.emit("\n" if self.in_pre else "  \n")
        elif tag == "hr":
            self.emit("\n\n---\n\n")
        elif tag in ("strong", "b"):
            self.emit("**")
        elif tag in ("em", "i"):
            self.emit("*")
        elif tag == "code" and not self.in_pre:
            self.emit("`")
        elif tag == "img":
            src = a.get("src", "")
            if src.startswith("//"):
                src = "https:" + src
            elif src.startswith("/"):
                src = "https://atcoder.jp" + src
            self.emit(f"![]({src})")
        elif tag == "table":
            self.row_count = 0
            self.emit("\n\n")
        elif tag == "tr":
            self.cells = 0
            self.emit("\n|")
        elif tag in ("td", "th"):
            self.cells += 1
            self.emit(" ")

    def handle_endtag(self, tag):
        if not self.capturing:
            return
        if tag == "span":
            self.span_depth -= 1
            if self.span_depth == 0:
                self.capturing = False
        elif tag in ("h1", "h2", "h3", "h4", "p", "div", "section"):
            self.emit("\n\n")
        elif tag == "pre":
            self.in_pre = False
            if self.out and not self.out[-1].endswith("\n"):
                self.emit("\n")
            self.emit("```\n\n")
        elif tag == "var":
            self.in_var = False
            if not self.in_pre:
                self.emit("$")
        elif tag in ("ul", "ol"):
            if self.lists:
                self.lists.pop()
                self.ol_counters.pop()
            self.emit("\n\n")
        elif tag in ("strong", "b"):
            self.emit("**")
        elif tag in ("em", "i"):
            self.emit("*")
        elif tag == "code" and not self.in_pre:
            self.emit("`")
        elif tag in ("td", "th"):
            self.emit(" |")
        elif tag == "tr":
            self.row_count += 1
            if self.row_count == 1:
                # 1 行目の後に Markdown の表ヘッダ区切りを入れる
                self.emit("\n|" + " --- |" * max(self.cells, 1))
        elif tag == "table":
            self.emit("\n\n")

    def handle_data(self, data):
        if not self.capturing:
            return
        if self.in_pre:
            self.emit(data)
        else:
            text = re.sub(r"\s+", " ", data)
            if self.in_var:
                text = text.strip()
            # 行頭の空白は Markdown でコードブロック扱いになるので落とす
            if not self.out or self.out[-1].endswith("\n"):
                text = text.lstrip()
            self.emit(text)

    def markdown(self):
        text = "".join(self.out)
        text = re.sub(r"[ \t]+\n", lambda m: "  \n" if m.group(0).startswith("  ") else "\n", text)
        text = re.sub(r"\n{3,}", "\n\n", text)
        return text.strip() + "\n"


def convert(page, lang):
    p = StatementParser(lang)
    p.feed(page)
    return p.markdown() if "".join(p.out).strip() else None


def check(url):
    """問題ページがあるかを調べて終了コードで返す (docstring 参照)。"""
    import urllib.error

    jar = LWPCookieJar()
    if os.path.exists(OJ_JAR):
        try:
            jar.load(OJ_JAR, ignore_discard=True)
        except Exception:
            pass
    opener = urllib.request.build_opener(urllib.request.HTTPCookieProcessor(jar))
    req = urllib.request.Request(url, headers={"User-Agent": "Mozilla/5.0"})
    try:
        with opener.open(req, timeout=20) as res:
            # ログインが要るページはログイン画面へ転送される
            return 3 if "/login" in res.geturl() else 0
    except urllib.error.HTTPError as e:
        return 2 if e.code == 404 else 1
    except Exception:
        return 1


def main():
    if len(sys.argv) == 3 and sys.argv[1] == "--check":
        sys.exit(check(sys.argv[2]))
    if len(sys.argv) != 3:
        print(__doc__)
        sys.exit(1)
    url, out_path = sys.argv[1], sys.argv[2]

    try:
        page = fetch(url)
    except Exception as e:
        print(f"[ERROR] failed to fetch {url}: {e}")
        sys.exit(1)

    body = convert(page, "ja") or convert(page, "en")
    if body is None:
        print(f"[ERROR] problem statement not found in {url}")
        sys.exit(1)

    m = re.search(r"<title>(.*?)</title>", page, re.S)
    title = html.unescape(m.group(1).strip()) if m else url
    m = re.search(r"(Time Limit:[^<]*|実行時間制限:[^<]*)", page)
    limits = re.sub(r"\s+", " ", m.group(1)).strip() if m else ""

    header = f"# {title}\n\n{url}\n\n"
    if limits:
        header += f"{limits}\n\n"
    with open(out_path, "w", encoding="utf-8") as f:
        f.write(header + "---\n\n" + body)


if __name__ == "__main__":
    main()
