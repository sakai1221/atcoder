#!/usr/bin/env bash
# Usage: ./new_contest.sh abc300 [a b c d ...]
# Creates contest/<id>/<problem>/main.cpp from the template and downloads
# sample test cases into contest/<id>/<problem>/test/ via `oj`.
# 問題ページが存在しない (404 など) 問題はディレクトリを作らずにエラーにする。
# 問題を指定しないとき (a ~ h 全部) は、存在しない問題 (7 問のコンテストの h など) は飛ばすだけ。
set -e

if [ -z "$1" ]; then
    echo "usage: $0 <contest_id> [problem_letters...]"
    echo "example: $0 abc300"
    echo "example: $0 abc300 a b c"
    exit 1
fi

CONTEST="$1"
shift

if [ "$#" -eq 0 ]; then
    PROBLEMS=(a b c d e f g h)
    EXPLICIT=0
else
    PROBLEMS=("$@")
    EXPLICIT=1
fi

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TEMPLATE="$ROOT/template/template.cpp"
CONTEST_DIR="$ROOT/contest/$CONTEST"

# Existing files are never overwritten; only missing ones are added.
prepared=0
failed=0
for p in "${PROBLEMS[@]}"; do
    DIR="$CONTEST_DIR/$p"
    URL="https://atcoder.jp/contests/$CONTEST/tasks/${CONTEST}_$p"
    echo "==> $p : $URL"

    # まだ準備していない問題は、ページがあるか確かめてからディレクトリを作る
    if [ ! -f "$DIR/main.cpp" ]; then
        code=0
        python3 "$ROOT/fetch_problem.py" --check "$URL" || code=$?
        if [ "$code" != 0 ]; then
            if [ "$code" = 2 ] && [ "$EXPLICIT" = 0 ]; then
                echo "    (この問題はない。スキップ)"
                continue
            fi
            case "$code" in
                2) echo "    [ERROR] 問題が存在しない (コンテスト名・問題の記号の間違い / まだ始まっていないコンテスト)" ;;
                3) echo "    [ERROR] ログインが必要なページ (docs/README.md の「ログイン」を参照)" ;;
                *) echo "    [ERROR] 問題ページを取得できない (ネットワークを確認)" ;;
            esac
            echo "    ディレクトリは作らない"
            failed=$((failed + 1))
            continue
        fi
    fi
    mkdir -p "$DIR"
    prepared=$((prepared + 1))

    if [ -f "$DIR/main.cpp" ]; then
        echo "    main.cpp   : kept (already exists)"
    else
        cp "$TEMPLATE" "$DIR/main.cpp"
        echo "    main.cpp   : created from template"
    fi

    # Samples: download into a temp dir, then copy only files missing from test/.
    # oj runs inside $DIR so that `oj submit` can find the problem from its history.
    if command -v oj >/dev/null 2>&1; then
        TMP="$(mktemp -d)"
        if (cd "$DIR" && oj download "$URL" -d "$TMP" >/dev/null 2>&1); then
            mkdir -p "$DIR/test"
            added=0
            for f in "$TMP"/*; do
                [ -e "$f" ] || continue
                if [ ! -e "$DIR/test/$(basename "$f")" ]; then
                    cp "$f" "$DIR/test/"
                    added=$((added + 1))
                fi
            done
            echo "    test/      : $added file(s) added"
        else
            echo "    test/      : download failed (problem may not exist or contest not started)"
        fi
        rm -rf "$TMP"
    else
        echo "    test/      : oj not installed yet; skipped"
    fi

    if [ -f "$DIR/problem.md" ]; then
        echo "    problem.md : kept (already exists)"
    elif python3 "$ROOT/fetch_problem.py" "$URL" "$DIR/problem.md" >/dev/null 2>&1; then
        echo "    problem.md : saved"
    else
        echo "    problem.md : download failed"
    fi
done

if [ "$prepared" = 0 ]; then
    echo "[ERROR] 準備できた問題がない (コンテスト名の間違い / まだ始まっていないコンテスト)。ディレクトリは作っていない"
    exit 1
fi
echo "Done: $CONTEST_DIR"
[ "$failed" = 0 ] || exit 1
