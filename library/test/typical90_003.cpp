// verify: https://atcoder.jp/contests/typical90/tasks/typical90_c
// test: contest/typical90/c/test
#include <bits/stdc++.h>
using namespace std;
using ll = long long;
#include <atcoder/all>
using namespace atcoder;
#include "graph/tree_diameter.hpp"

int main() {
  int n;
  cin >> n;
  vector<vector<int>> g(n);
  for (int i = 0; i < n - 1; i++) {
    int u, v;
    cin >> u >> v;
    u--, v--;
    g[u].push_back(v);
    g[v].push_back(u);
  }
  auto [len, u, v] = tree_diameter(g);
  // 直径上の頂点数 = len + 1 になっているか (restore_path の確認)
  assert((int)restore_path(bfs(g, u).par, v).size() == len + 1);
  cout << len + 1 << '\n';
}
