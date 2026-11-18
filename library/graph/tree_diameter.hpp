#pragma once
#include <bits/stdc++.h>
#include "graph/bfs.hpp"

// 木の直径 (重みなし)
//   auto [len, u, v] = tree_diameter(g);
//     len: 直径の長さ (辺の本数)、u, v: 直径の両端
//   直径上の頂点列が欲しいときは restore_path(bfs(g, u).par, v)
// 原理: 任意の頂点から一番遠い頂点は直径の端点 → BFS 2回
// 計算量: O(N)
// verify: typical90 003

struct TreeDiameter {
  int len, u, v;
};

inline TreeDiameter tree_diameter(const std::vector<std::vector<int>> &g) {
  auto d1 = bfs(g, 0).dist;
  int u = std::max_element(d1.begin(), d1.end()) - d1.begin();
  auto d2 = bfs(g, u).dist;
  int v = std::max_element(d2.begin(), d2.end()) - d2.begin();
  return {d2[v], u, v};
}
