#pragma once
#include <bits/stdc++.h>

// ランレングス圧縮 (同じ値が続く部分を {値, 個数} にまとめる)
//   rle(s): 例: "ooxxxo" → {{'o', 2}, {'x', 3}, {'o', 1}}
//   string 以外 (vector<int> など) にも使える
// 計算量: O(N)
// verify: typical90 084

template <class T>
std::vector<std::pair<typename T::value_type, long long>> rle(const T &s) {
  std::vector<std::pair<typename T::value_type, long long>> res;
  for (const auto &c : s) {
    if (!res.empty() && res.back().first == c) {
      res.back().second++;
    } else {
      res.push_back({c, 1});
    }
  }
  return res;
}
