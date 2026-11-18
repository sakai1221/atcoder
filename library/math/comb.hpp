#pragma once
#include <bits/stdc++.h>

// 二項係数など (mod p)。テンプレートの `using mint = ...;` より後ろで include する
//   comb(n, k) : nCk (k < 0 や k > n なら 0)
//   perm(n, k) : nPk (k < 0 や k > n なら 0)
//   homo(n, k) : nHk (n 種類から重複を許して k 個選ぶ)。nHk = (n+k-1)Ck
//   fact(n), ifact(n): n! と 1/n!
// 階乗の表は初めて使ったときに自動で作られ、大きい n が来たら自動で伸びる (初期化の呼び出しは不要)
// 計算量: 表を作るのは必要な n まで O(n)、以降は 1 回 O(1)
// 注意: n は mod (素数) より小さいこと。n! が mod の倍数になると逆元がない
// verify: typical90 050

struct CombTable {
  std::vector<mint> f{1}, inv_f{1};  // f[i] = i!, inv_f[i] = 1/i!
  void ensure(int n) {
    int old = f.size();
    if (n < old) return;
    assert(n < (int)mint::mod());
    int sz = std::max(n + 1, old * 2);
    f.resize(sz);
    inv_f.resize(sz);
    for (int i = old; i < sz; i++) f[i] = f[i - 1] * i;
    inv_f[sz - 1] = f[sz - 1].inv();
    for (int i = sz - 1; i > old; i--) inv_f[i - 1] = inv_f[i] * i;
  }
};

inline CombTable &comb_table() {
  static CombTable t;
  return t;
}

inline mint fact(int n) {
  assert(n >= 0);
  comb_table().ensure(n);
  return comb_table().f[n];
}

inline mint ifact(int n) {
  assert(n >= 0);
  comb_table().ensure(n);
  return comb_table().inv_f[n];
}

inline mint comb(int n, int k) {
  if (n < 0 || k < 0 || k > n) return 0;
  return fact(n) * ifact(k) * ifact(n - k);
}

inline mint perm(int n, int k) {
  if (n < 0 || k < 0 || k > n) return 0;
  return fact(n) * ifact(n - k);
}

inline mint homo(int n, int k) {
  if (n == 0 && k == 0) return 1;
  return comb(n + k - 1, k);
}
