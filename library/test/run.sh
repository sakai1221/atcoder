#!/bin/bash
# 自作ライブラリの verify。library/test/*.cpp を bundle.py で展開してからビルドし、
# 各ファイルの「// test: <dir>」に書いたサンプルでテストする。
#   bash library/test/run.sh                 # 全部
#   bash library/test/run.sh typical90_003   # 指定したものだけ
# 展開後のコードを library/ なしでビルドするので、展開 (s の提出時の処理) の確認も兼ねる。
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
work="$(mktemp -d)"
trap 'rm -rf "$work"' EXIT

if [ $# -gt 0 ]; then
    files=()
    for name in "$@"; do files+=("$ROOT/library/test/${name%.cpp}.cpp"); done
else
    files=("$ROOT"/library/test/*.cpp)
fi

fail=0
for f in "${files[@]}"; do
    name="$(basename "$f" .cpp)"
    dir="$(sed -n 's#^// test: *##p' "$f" | head -1)"
    echo "=== $name ($dir)"
    if [ ! -d "$ROOT/$dir" ]; then
        echo "  テストケースが見つからない: $dir (new で問題を準備する)"
        fail=1
        continue
    fi
    python3 "$ROOT/bundle.py" "$f" > "$work/$name.cpp" &&
    g++ -std=c++23 -O2 -Wall -Wextra -I "$ROOT/ac-library" "$work/$name.cpp" -o "$work/$name" &&
    oj test -c "$work/$name" -d "$ROOT/$dir" > "$work/$name.log" 2>&1
    if [ $? -eq 0 ]; then
        echo "  AC"
    else
        cat "$work/$name.log" 2>/dev/null
        fail=1
    fi
done
exit $fail
