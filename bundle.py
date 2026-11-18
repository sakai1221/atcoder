#!/usr/bin/env python3
"""main.cpp の自作ライブラリの #include を中身に展開して標準出力に出す。s から呼ばれる。

  python3 bundle.py main.cpp > bundled.cpp

- 展開するのは library/ の中のファイルを指す #include "..." だけ (入れ子も展開し、同じファイルは1回だけ)
- <bits/stdc++.h> や <atcoder/...> は AtCoder 側にあるのでそのまま残す
- #ifdef LOCAL の中 (debug.hpp) は手元専用なのでそのまま残す
"""
import re
import sys
from pathlib import Path

LIB = Path(__file__).resolve().parent / "library"

INCLUDE = re.compile(r'^\s*#\s*include\s*"([^"]+)"')
IF = re.compile(r"^\s*#\s*if")
IFDEF_LOCAL = re.compile(r"^\s*#\s*ifdef\s+LOCAL\b")
ELSE = re.compile(r"^\s*#\s*(else|elif)\b")
ENDIF = re.compile(r"^\s*#\s*endif\b")
PRAGMA_ONCE = re.compile(r"^\s*#\s*pragma\s+once\b")


def resolve(name: str, cur_dir: Path) -> Path | None:
    for base in (cur_dir, LIB):
        p = (base / name).resolve()
        if p.is_file() and LIB in p.parents:
            return p
    return None


def expand(path: Path, out: list[str], done: set[Path], is_main: bool) -> None:
    depth = 0
    local_depth = None  # #ifdef LOCAL の真の側にいる間、その深さ
    for line in path.read_text().splitlines():
        if IF.match(line):
            depth += 1
            if local_depth is None and IFDEF_LOCAL.match(line):
                local_depth = depth
        elif ELSE.match(line):
            if local_depth == depth:
                local_depth = None
        elif ENDIF.match(line):
            if local_depth == depth:
                local_depth = None
            depth -= 1

        if not is_main and PRAGMA_ONCE.match(line):
            continue

        m = INCLUDE.match(line)
        if m and local_depth is None:
            p = resolve(m.group(1), path.parent)
            if p is None:
                print(f"bundle.py: warning: {m.group(1)} が library/ に見つからないので展開しない", file=sys.stderr)
            elif p not in done:
                done.add(p)
                out.append(f"// ---- {p.relative_to(LIB)} ----")
                expand(p, out, done, is_main=False)
                out.append(f"// ---- end {p.relative_to(LIB)} ----")
            continue
        out.append(line)


def main() -> None:
    if len(sys.argv) != 2:
        print("usage: bundle.py <main.cpp>", file=sys.stderr)
        sys.exit(1)
    out: list[str] = []
    expand(Path(sys.argv[1]).resolve(), out, set(), is_main=True)
    print("\n".join(out))


if __name__ == "__main__":
    main()
