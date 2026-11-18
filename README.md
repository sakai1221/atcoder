# AtCoder template / library

AtCoder (C++) 用のテンプレート・スニペット・自作ライブラリ。

**生成 AI を使って作成したコードを含みます。**
[AtCoder 生成AI対策ルール](https://info.atcoder.jp/entry/llm-rules-ja) に従い、コンテスト前に公開しています。
提出コードの先頭には、このリポジトリの URL を記載しています。

## 構成

```
template/        提出コードの雛形
library/         自作ライブラリ (header-only)。test/ は verify 用
.vscode/         スニペット (cpp.code-snippets) と VSCode 設定
bundle.py        提出用に library/ の #include を展開する
*.sh / *.py      手元の環境用スクリプト
tools/           手元の環境用 VSCode 拡張
```

公式ライブラリは [AtCoder Library](https://github.com/atcoder/ac-library) を使用しています。
