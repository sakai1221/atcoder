#pragma once
#include <bits/stdc++.h>

// BFS (重みなしグラフの最短距離)
//   auto [dist, par] = bfs(g, s);
//     dist[v]: s から v への距離 (辺の本数)。到達できなければ -1
//     par[v] : 最短経路で v の1つ前の頂点。s と到達できない頂点は -1
//   restore_path(par, t): s → t の頂点列 (s, ..., t)。t は到達できる頂点にする
// 計算量: O(N + M)
// verify: typical90 003

struct BFSResult {
  std::vector<int> dist, par;
};

inline BFSResult bfs(const std::vector<std::vector<int>> &g, int s) {
  int n = g.size();
  std::vector<int> dist(n, -1), par(n, -1);
  std::queue<int> q;
  dist[s] = 0;
  q.push(s);
  while (!q.empty()) {
    int v = q.front();
    q.pop();
    for (int nv : g[v]) {
      if (dist[nv] != -1) continue;
      dist[nv] = dist[v] + 1;
      par[nv] = v;
      q.push(nv);
    }
  }
  return {dist, par};
}

inline std::vector<int> restore_path(const std::vector<int> &par, int t) {
  std::vector<int> path;
  for (int v = t; v != -1; v = par[v]) path.push_back(v);
  std::reverse(path.begin(), path.end());
  return path;
}
