#!/usr/bin/env python3
"""ブラウザからエクスポートした Netscape 形式の cookies.txt を
online-judge-tools (oj) が読む LWP 形式の cookie.jar に変換して配置する。

AtCoder のログインは Cloudflare Turnstile で保護されており oj の CUI ログインは
不可能なため、Turnstile を通せる実ブラウザのセッション Cookie を移植する。

使い方:
    python3 import_cookies.py <exported_cookies.txt>

<exported_cookies.txt> は拡張機能「Get cookies.txt LOCALLY」等で
atcoder.jp にログイン済みの状態からエクスポートした Netscape 形式ファイル。
"""
import sys
import time
import os
from http.cookiejar import LWPCookieJar, Cookie

OJ_JAR = os.path.expanduser(
    "~/.local/share/online-judge-tools/cookie.jar"
)


def parse_netscape(path):
    """Netscape cookies.txt を手パースして Cookie を列挙する。
    MozillaCookieJar.load は書式に厳しく拡張機能の出力で落ちることがあるため自前で読む。"""
    cookies = []
    with open(path, encoding="utf-8") as f:
        for raw in f:
            line = raw.rstrip("\n")
            http_only = False
            if line.startswith("#HttpOnly_"):
                http_only = True
                line = line[len("#HttpOnly_"):]
            if not line or line.startswith("#"):
                continue
            parts = line.split("\t")
            if len(parts) != 7:
                continue
            domain, include_sub, path, secure, expires, name, value = parts
            cookies.append({
                "domain": domain,
                "include_sub": include_sub.upper() == "TRUE",
                "path": path,
                "secure": secure.upper() == "TRUE",
                "expires": int(expires) if expires.isdigit() else None,
                "name": name,
                "value": value,
                "http_only": http_only,
            })
    return cookies


def main():
    if len(sys.argv) != 2:
        print(__doc__)
        sys.exit(1)
    src = sys.argv[1]
    if not os.path.exists(src):
        print(f"[ERROR] file not found: {src}")
        sys.exit(1)

    parsed = parse_netscape(src)
    ac = [c for c in parsed if "atcoder.jp" in c["domain"]]
    if not ac:
        print("[ERROR] atcoder.jp の Cookie が見つかりません。"
              "atcoder.jp にログイン済みの状態でエクスポートしたか確認してください。")
        sys.exit(1)

    os.makedirs(os.path.dirname(OJ_JAR), exist_ok=True)
    jar = LWPCookieJar(OJ_JAR)
    for c in ac:
        cookie = Cookie(
            version=0, name=c["name"], value=c["value"],
            port=None, port_specified=False,
            domain=c["domain"], domain_specified=True,
            domain_initial_dot=c["domain"].startswith("."),
            path=c["path"], path_specified=True,
            secure=c["secure"], expires=c["expires"],
            discard=False, comment=None, comment_url=None,
            rest={"HttpOnly": None} if c["http_only"] else {},
            rfc2109=False,
        )
        jar.set_cookie(cookie)
    jar.save(ignore_discard=True, ignore_expires=True)

    names = sorted({c["name"] for c in ac})
    print(f"[OK] {len(ac)} 個の atcoder.jp Cookie を {OJ_JAR} に書き込みました")
    print(f"     cookies: {', '.join(names)}")
    if "REVEL_SESSION" not in names:
        print("[WARN] REVEL_SESSION が含まれていません。ログインセッションが取れていない可能性。")


if __name__ == "__main__":
    main()
