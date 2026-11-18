// ワークスペースの .vscode/.open-request を監視し、書き込まれた JSON に従ってファイルを開く。
// ターミナル側 (aliases.sh の new / go / stl) が書き込む。
//   {"type": "problem", "dir": "/abs/contest/abc300/a"}  左に main.cpp、右に problem.md のプレビュー
//   {"type": "preview", "file": "/abs/docs/stl.md"}      右に Markdown プレビュー
const vscode = require('vscode');
const fs = require('fs');
const path = require('path');

const PREVIEW = 'vscode.markdown.preview.editor';

function activate(context) {
  for (const folder of vscode.workspace.workspaceFolders || []) {
    const reqPath = path.join(folder.uri.fsPath, '.vscode', '.open-request');
    const watcher = vscode.workspace.createFileSystemWatcher(
      new vscode.RelativePattern(folder, '.vscode/.open-request'));
    let timer = null;
    // 1回の書き込みで変更イベントが複数回来ることがあるのでまとめる
    const onEvent = () => {
      clearTimeout(timer);
      timer = setTimeout(() => {
        handle(folder.uri.fsPath, reqPath).catch(e =>
          vscode.window.showErrorMessage(`atcoder-helper: ${e.message}`));
      }, 100);
    };
    watcher.onDidChange(onEvent);
    watcher.onDidCreate(onEvent);
    context.subscriptions.push(watcher);
  }
}

async function handle(root, reqPath) {
  const req = JSON.parse(fs.readFileSync(reqPath, 'utf8'));
  if (req.type === 'problem') {
    await openProblem(root, req.dir);
  } else if (req.type === 'preview') {
    await vscode.commands.executeCommand('vscode.openWith', vscode.Uri.file(req.file), PREVIEW,
      { viewColumn: vscode.ViewColumn.Two });
  }
}

async function openProblem(root, dir) {
  const main = path.join(dir, 'main.cpp');
  const problem = path.join(dir, 'problem.md');

  // 別の問題の main.cpp / problem.md のタブを閉じる (未保存のものは残す)
  const contestDir = path.join(root, 'contest') + path.sep;
  const stale = [];
  for (const group of vscode.window.tabGroups.all) {
    for (const tab of group.tabs) {
      const uri = tab.input && tab.input.uri;
      if (!uri || tab.isDirty) continue;
      const p = uri.fsPath;
      if (!p.startsWith(contestDir) || p === main || p === problem) continue;
      if (['main.cpp', 'problem.md'].includes(path.basename(p))) stale.push(tab);
    }
  }
  if (stale.length) await vscode.window.tabGroups.close(stale);

  if (fs.existsSync(problem)) {
    await vscode.commands.executeCommand('vscode.openWith', vscode.Uri.file(problem), PREVIEW,
      { viewColumn: vscode.ViewColumn.Two, preserveFocus: true });
  }
  if (fs.existsSync(main)) {
    await vscode.window.showTextDocument(vscode.Uri.file(main),
      { viewColumn: vscode.ViewColumn.One, preview: false });
  }
}

function deactivate() {}

module.exports = { activate, deactivate };
