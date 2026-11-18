# AtCoder shortcuts. Sourced from ~/.bashrc.
#   new <contest> [problems...]  : prepare problems and cd into the first one
#   t [s1 e2 ... | s | e | r | -l]: build ./main.cpp and run tests in test/ (default: sample + edge)
#   s                            : submit ./main.cpp
#   r [COUNT] / r del            : random test with gen.py (+ compare with brute if any) / delete saved cases in random/
#   brute [py]                   : create brute.cpp (or brute.py) for r to compare answers with
#   edge [s1]                    : add a hand-made test case test/edge-<N>.in/.out (copied from s1 etc.)
#   go <problem> / a ~ h         : move to another problem of the current contest
#   stl [WORD | -l]              : show docs/stl.md (VSCode preview / matching sections / less)

ATCODER_ROOT="$HOME/atcoder"

# VSCode に開くファイルを頼む。拡張 atcoder-helper (tools/vscode-atcoder-helper) が
# .vscode/.open-request の変更を検知して開く。拡張が入っていなければ何も起きない。
_vscode_request() {
    printf '%s\n' "$1" > "$ATCODER_ROOT/.vscode/.open-request"
}

# 今いる問題を開く: 左に main.cpp、右に problem.md のプレビュー (前の問題のタブは閉じる)
_open_problem() {
    _vscode_request "{\"type\": \"problem\", \"dir\": \"$(pwd)\", \"t\": $(date +%s%N)}"
}

new() {
    if [ -z "$1" ]; then
        echo "usage: new <contest_id> [problem_letters...]"
        echo "example: new typical90 v"
        return 1
    fi
    "$ATCODER_ROOT/new_contest.sh" "$@" || return 1
    local first="${2:-a}"
    if [ ! -d "$ATCODER_ROOT/contest/$1/$first" ]; then
        echo "$1/$first は準備されていない"
        return 1
    fi
    cd "$ATCODER_ROOT/contest/$1/$first" || return 1
    _open_problem
}

# 今のコンテストの別の問題へ移動して VSCode の表示も切り替える
#   go c     contest/<今のコンテスト>/c へ (まだ準備していなければ new で準備する)
#   a ~ h    go a ~ go h の短縮
go() {
    if [ -z "$1" ]; then
        echo "usage: go <problem>   (例: go c、典型90 なら go aa)"
        return 1
    fi
    local rel="${PWD#"$ATCODER_ROOT/contest/"}"
    if [ "$rel" = "$PWD" ] || [ -z "$rel" ]; then
        echo "contest/<contest>/ の中で実行する"
        return 1
    fi
    local contest="${rel%%/*}"
    if [ -f "$ATCODER_ROOT/contest/$contest/$1/main.cpp" ]; then
        cd "$ATCODER_ROOT/contest/$contest/$1" || return 1
        _open_problem
    else
        new "$contest" "$1"
    fi
}
for _p in a b c d e f g h; do
    eval "$_p() { go $_p; }"
done
unset _p

# テストの指定方法 (t と edge で共通)
#   s / e / r      test/sample-* / test/edge-* / random/* のすべて
#   s1 / e2 / r123 test/sample-1 / test/edge-2 / random/123
#   sample-1 など  test/ のファイル名そのまま (.in は省略可)
#
# t           sample と edge をすべて実行 (random は含めない)
# t s1 e2     指定したケースだけ
# t e         edge をすべて
# t r         random をすべて (r で見つかった、落ちた / 止まらなかった入力。random/ にある)
# t -l        ケースと短い名前の一覧を表示するだけ
t() {
    if [ ! -f main.cpp ]; then
        echo "main.cpp not found in $(pwd)"
        return 1
    fi
    if [ "$1" = "-l" ]; then
        _t_list
        return 0
    fi

    local -a sels=("$@")
    [ "${#sels[@]}" -eq 0 ] && sels=(s e)

    local -a paths=() rpaths=()
    local -A seen=()
    local sel f
    for sel in "${sels[@]}"; do
        local -a found=()
        mapfile -t found < <(_t_find "$sel")
        if [ "${#found[@]}" -eq 0 ]; then
            # 引数なしの t で edge がまだ無いだけなら黙って飛ばす
            [ "$#" -eq 0 ] && continue
            echo "$sel に当たるテストがない"
            _t_list
            return 1
        fi
        for f in "${found[@]}"; do
            [ -n "${seen[$f]:-}" ] && continue
            seen[$f]=1
            # oj test は -d のフォルダの中のファイルしか受け付けないので、test/ と random/ で分ける
            if [[ "$f" == random/* ]]; then
                rpaths+=("$f")
                [ -f "${f%.in}.out" ] && rpaths+=("${f%.in}.out")
            else
                paths+=("$f")
                [ -f "${f%.in}.out" ] && paths+=("${f%.in}.out")
            fi
        done
    done
    if [ "${#paths[@]}" -eq 0 ] && [ "${#rpaths[@]}" -eq 0 ]; then
        echo "実行するケースがない"
        return 1
    fi

    # -D_GLIBCXX_DEBUG: vector の範囲外アクセスなどをその場で検出して止める (手元のみ)
    g++ -std=c++23 -O2 -Wall -Wextra -DLOCAL -D_GLIBCXX_DEBUG \
        -I "$ATCODER_ROOT/library" -I "$ATCODER_ROOT/ac-library" \
        main.cpp -o main || return 1
    local status=0
    if [ "${#paths[@]}" -gt 0 ]; then
        oj test -c ./main -d test "${paths[@]}" || status=1
    fi
    if [ "${#rpaths[@]}" -gt 0 ]; then
        echo "=== random/ (.out (brute の答え) があるケースは答えも比べる。無いケースは落ちない・終わるかだけ) ==="
        oj test -c ./main -d random "${rpaths[@]}" || status=1
    fi
    return $status
}

# 指定 (s / s1 / sample-1 など) に当たる test/*.in を 1 行ずつ出力する
_t_find() {
    local sel="${1%.in}" kind
    if [[ "$sel" =~ ^([ser])([0-9]*)$ ]]; then
        case "${BASH_REMATCH[1]}" in
            s) kind=sample ;;
            e) kind=edge ;;
            r)
                if [ -z "${BASH_REMATCH[2]}" ]; then
                    find random -maxdepth 1 -name '*.in' 2> /dev/null | sort -V
                elif [ -f "random/${BASH_REMATCH[2]}.in" ]; then
                    echo "random/${BASH_REMATCH[2]}.in"
                fi
                return
                ;;
        esac
        if [ -z "${BASH_REMATCH[2]}" ]; then
            find test -maxdepth 1 -name "$kind-*.in" 2> /dev/null | sort -V
        elif [ -f "test/$kind-${BASH_REMATCH[2]}.in" ]; then
            echo "test/$kind-${BASH_REMATCH[2]}.in"
        fi
    elif [ -f "test/$sel.in" ]; then
        echo "test/$sel.in"
    fi
}

_t_list() {
    local -a all=()
    mapfile -t all < <(
        find test -maxdepth 1 -name '*.in' 2> /dev/null | sort -V
        find random -maxdepth 1 -name '*.in' 2> /dev/null | sort -V
    )
    if [ "${#all[@]}" -eq 0 ]; then
        echo "test/ にも random/ にもケースがない"
        return
    fi
    local c name short
    for c in "${all[@]}"; do
        name="${c%.in}"
        case "$name" in
            test/sample-*) short="s${name#test/sample-}" ;;
            test/edge-*) short="e${name#test/edge-}" ;;
            random/*) short="r${name#random/}" ;;
            *) short="${name#test/}" ;;
        esac
        printf '  %-12s %s\n' "$short" "$name"
    done
}

# r           ランダムテスト 100 ケース (r 1000 でケース数を指定)
# r del       random/ (r で見つかった反例) を全部消す
r() {
    bash "$ATCODER_ROOT/stress.sh" "$@"
}

# 愚直解 (遅いが確実に正しい解) を作って開く。あると r が main の答えと比べる
#   brute       brute.cpp を template.cpp から作る
#   brute py    brute.py を作る (Python のほうが書きやすいとき)
brute() {
    if [ ! -f main.cpp ]; then
        echo "main.cpp not found in $(pwd)"
        return 1
    fi
    local file=brute.cpp
    [ "${1:-}" = "py" ] && file=brute.py
    if [ -e brute.cpp ] || [ -e brute.py ]; then
        echo "brute.cpp か brute.py がもうある (r は brute.cpp を優先して使う)"
    elif [ "$file" = brute.cpp ]; then
        cp "$ATCODER_ROOT/template/template.cpp" brute.cpp
        echo "created: brute.cpp。全探索などで確実に正しい解を書いて r (小さい入力なら遅くてよい)"
    else
        printf '%s\n' "# 愚直解。r が python3 brute.py < 入力 として呼び、main の答えと比べる" "import sys" "input = sys.stdin.readline" "" > brute.py
        echo "created: brute.py。全探索などで確実に正しい解を書いて r (小さい入力なら遅くてよい)"
    fi
    command -v code > /dev/null && code "$([ -e brute.cpp ] && echo brute.cpp || echo brute.py)"
}

# 自作のテストケース (入力と答え) を test/edge-<番号> として作って開く。t で毎回チェックされる
#   edge        .in は sample-1.in のコピー (入力形式の見本)、.out は空
#   edge s2     sample-2 の .in と .out をコピー (t と同じ指定方法: e1, r123, sample-2 なども可)
# 番号は空いている最小の番号 (edge-1, edge-2, ...)。コピーしたら入力と正しい答えに書き換える。
edge() {
    if [ ! -f main.cpp ]; then
        echo "main.cpp not found in $(pwd)"
        return 1
    fi
    mkdir -p test
    local i=1
    while [ -e "test/edge-$i.in" ] || [ -e "test/edge-$i.out" ]; do
        i=$((i + 1))
    done
    local name="test/edge-$i"

    if [ -n "$1" ]; then
        local -a found=()
        mapfile -t found < <(_t_find "$1")
        if [ "${#found[@]}" -ne 1 ]; then
            echo "$1 に当たるテストが 1 つに決まらない (s1 のように番号まで指定する)"
            _t_list
            return 1
        fi
        local src="${found[0]%.in}"
        cp "$src.in" "$name.in"
        if [ -f "$src.out" ]; then
            cp "$src.out" "$name.out"
        else
            : > "$name.out"
        fi
        echo "created: $name.in / .out ($(basename "$src") のコピー)"
    else
        if [ -f test/sample-1.in ]; then
            cp test/sample-1.in "$name.in"
        else
            : > "$name.in"
        fi
        : > "$name.out"
        echo "created: $name.in (sample-1.in のコピー), $name.out (空)"
    fi
    echo "入力と正しい答えに書き換えて t"
    if command -v code > /dev/null; then
        code "$name.in" "$name.out"
    fi
}

# docs/stl.md (std の早見表) を表示する
#   stl          VSCode の右側にプレビューで開く
#   stl map      見出しに "map" を含むセクションだけターミナルに表示 (大文字小文字は区別しない)
#   stl -l       全体を less で開く (q で閉じる、/map で検索)
stl() {
    local file="$ATCODER_ROOT/docs/stl.md"
    if [ -z "$1" ]; then
        _vscode_request "{\"type\": \"preview\", \"file\": \"$file\", \"t\": $(date +%s%N)}"
    elif [ "$1" = "-l" ]; then
        less "$file"
    else
        awk -v q="$1" '
            /^## / { show = index(tolower($0), tolower(q)) > 0 }
            /^---$/ { next }
            show { print; found = 1 }
            END { if (!found) print "\"" q "\" を含む見出しがない (stl で全体を見る)" }
        ' "$file"
    fi
}

s() {
    if [ ! -f main.cpp ]; then
        echo "main.cpp not found in $(pwd)"
        return 1
    fi
    # AtCoder's submit form has Cloudflare Turnstile (CAPTCHA), so CLI tools
    # (oj / acc) can't submit. Instead: copy main.cpp to the Windows clipboard
    # and open the submit page; paste and press the button in the browser.
    #
    # Task URL is given as an argument, or derived from contest/<contest>/<problem>
    # (same rule as new_contest.sh).
    local url="$1"
    if [ -z "$url" ]; then
        local problem contest
        problem="$(basename "$(pwd)")"
        contest="$(basename "$(dirname "$(pwd)")")"
        if [ "$(dirname "$(dirname "$(pwd)")")" != "$ATCODER_ROOT/contest" ]; then
            echo "not in contest/<contest>/<problem>; usage: s [TASK_URL]"
            return 1
        fi
        url="https://atcoder.jp/contests/$contest/tasks/${contest}_$problem"
    fi
    # https://atcoder.jp/contests/C/tasks/T -> https://atcoder.jp/contests/C/submit?taskScreenName=T
    local submit_url
    submit_url="$(echo "$url" | sed -E 's#^(https://atcoder\.jp/contests/[^/]+)/tasks/([^/?]+).*#\1/submit?taskScreenName=\2#')"

    # 自作ライブラリ (library/) の #include を中身に展開する。AtCoder には library/ がないため。
    # 展開後のコードが library/ なし (AtCoder と同じ条件) でコンパイルできるかも確認する。
    local bundled
    bundled="$(mktemp --suffix=.cpp)"
    python3 "$ATCODER_ROOT/bundle.py" main.cpp > "$bundled" || { rm -f "$bundled"; return 1; }
    if ! g++ -std=c++23 -fsyntax-only -I "$ATCODER_ROOT/ac-library" "$bundled"; then
        echo "展開後のコードがコンパイルできないので中止 (展開結果: $bundled)"
        return 1
    fi

    # clip.exe garbles UTF-8 (e.g. Japanese comments) but reads UTF-16LE correctly.
    iconv -f UTF-8 -t UTF-16LE "$bundled" | clip.exe || { rm -f "$bundled"; return 1; }
    rm -f "$bundled"
    echo "copied main.cpp (library expanded) to clipboard"
    echo "opening: $submit_url"
    # explorer.exe treats URLs with "?" as a path and opens File Explorer instead;
    # rundll32 url.dll hands the URL to the default browser as-is.
    rundll32.exe url.dll,FileProtocolHandler "$submit_url"
    echo "in the browser: choose language -> Ctrl+V -> CAPTCHA -> 提出"
}
