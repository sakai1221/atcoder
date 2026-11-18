#!/usr/bin/env bash
# Random testing for the problem in the current directory. Called by `r` (aliases.sh).
#
#   r [COUNT]   run COUNT random cases (default 100)
#   r del       delete the saved failing cases (random/)
#
# Needs gen.py (random input generator; created from template/gen.py on first run).
# Checks that main doesn't crash or exceed the time limit. If brute.cpp or brute.py
# (a slow but surely-correct solution; `brute` creates one) is in the folder, the answers
# are also compared with it (ignoring differences in whitespace / line breaks).
# A failing case is saved as random/<seed>.in (+ .out = brute's answer when brute exists);
# `t r` runs those (plain `t` doesn't).
set -u

if [ "${1:-}" = "del" ]; then
    if [ -d random ]; then
        n=$(find random -maxdepth 1 -name '*.in' | wc -l)
        rm -rf random
        echo "deleted random/ ($n cases)"
    else
        echo "random/ がない (消すものなし)"
    fi
    exit 0
fi
if [ -n "${1:-}" ] && ! [[ "$1" =~ ^[0-9]+$ ]]; then
    echo "usage: r [COUNT] | r del"
    exit 1
fi

COUNT="${1:-100}"
TIME_LIMIT="${TIME_LIMIT:-2}"   # seconds; override like `TIME_LIMIT=4 r`
BRUTE_LIMIT="${BRUTE_LIMIT:-10}" # brute は遅くてよいので長めに待つ
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CXXFLAGS=(-std=c++23 -O2 -Wall -Wextra -DLOCAL -I "$ROOT/library" -I "$ROOT/ac-library")

if [ ! -f main.cpp ]; then
    echo "main.cpp not found in $(pwd)"
    exit 1
fi
if [ ! -f gen.py ]; then
    cp "$ROOT/template/gen.py" gen.py
    echo "created gen.py from template."
    echo "edit it to print random input in this problem's format, then run r again."
    exit 1
fi

echo "build main.cpp"
g++ "${CXXFLAGS[@]}" main.cpp -o main || exit 1

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

# 愚直解 (あれば答えを比べる)。brute.cpp を優先
brute=()
if [ -f brute.cpp ]; then
    echo "build brute.cpp"
    g++ "${CXXFLAGS[@]}" brute.cpp -o "$TMP/brute" || exit 1
    brute=("$TMP/brute")
elif [ -f brute.py ]; then
    brute=(python3 brute.py)
fi

save_case() {
    mkdir -p random
    cp "$TMP/in" "random/$1.in"
    if [ "${#brute[@]}" -gt 0 ] && [ -f "$TMP/expected" ]; then
        cp "$TMP/expected" "random/$1.out"
        echo "saved: random/$1.in / .out (.out は brute の答え。直したら t r$1 で確認、r del で random/ を全部消す)"
    else
        echo "saved: random/$1.in  (直したら t r$1 で確認、r del で random/ を全部消す)"
    fi
}

show_output() {  # $1: 見出し, $2: ファイル
    echo "--- $1 ---"
    head -n 20 "$2"
    [ "$(wc -l < "$2")" -gt 20 ] && echo "... ($(wc -l < "$2") lines)"
}

# 空白・改行の違いを無視して比べる
same_output() {
    cmp -s <(tr -s '[:space:]' '\n' < "$1" | sed '/^$/d') <(tr -s '[:space:]' '\n' < "$2" | sed '/^$/d')
}

show_input() {
    echo "--- input ---"
    head -n 20 "$TMP/in"
    [ "$(wc -l < "$TMP/in")" -gt 20 ] && echo "... ($(wc -l < "$TMP/in") lines)"
}

max_ms=0
for ((i = 1; i <= COUNT; i++)); do
    seed=$RANDOM$RANDOM
    rm -f "$TMP/expected"  # 前のケースの brute の答えを使わないように
    if ! python3 gen.py "$seed" > "$TMP/in"; then
        echo "gen.py failed (seed $seed)"
        exit 1
    fi

    start=$(date +%s%N)
    timeout "$TIME_LIMIT" ./main < "$TMP/in" > "$TMP/actual" 2> "$TMP/stderr"
    status=$?
    ms=$(( ($(date +%s%N) - start) / 1000000 ))
    [ "$ms" -gt "$max_ms" ] && max_ms=$ms

    if [ "$status" = 124 ]; then
        echo "[TLE] case $i (seed $seed): over ${TIME_LIMIT}s"
        show_input
        save_case "$seed"
        exit 1
    elif [ "$status" != 0 ]; then
        echo "[RE] case $i (seed $seed): exit code $status"
        show_input
        echo "--- stderr ---"
        tail -n 20 "$TMP/stderr"
        save_case "$seed"
        exit 1
    fi

    if [ "${#brute[@]}" -gt 0 ]; then
        timeout "$BRUTE_LIMIT" "${brute[@]}" < "$TMP/in" > "$TMP/expected.tmp" 2> "$TMP/brute_stderr"
        bstatus=$?
        if [ "$bstatus" != 0 ]; then
            echo "[brute failed] case $i (seed $seed): exit code $bstatus$([ "$bstatus" = 124 ] && echo " (over ${BRUTE_LIMIT}s。gen.py の値を小さくするか BRUTE_LIMIT=30 r)")"
            show_input
            echo "--- brute stderr ---"
            tail -n 20 "$TMP/brute_stderr"
            exit 1
        fi
        mv "$TMP/expected.tmp" "$TMP/expected"
        if ! same_output "$TMP/expected" "$TMP/actual"; then
            echo "[WA] case $i (seed $seed): main と brute の答えが違う"
            show_input
            show_output "brute (expected)" "$TMP/expected"
            show_output "main (actual)" "$TMP/actual"
            save_case "$seed"
            exit 1
        fi
    fi
done

if [ "${#brute[@]}" -gt 0 ]; then
    echo "[OK] all $COUNT cases: same answers as brute, no crash / TLE (max ${max_ms} ms)"
else
    echo "[OK] all $COUNT cases ran without crash / TLE (max ${max_ms} ms)  (答えも比べるなら brute で愚直解を作る)"
fi
