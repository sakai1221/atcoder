// verify: https://atcoder.jp/contests/typical90/tasks/typical90_ax
// test: contest/typical90/ax/test
#include <bits/stdc++.h>
using namespace std;
using ll = long long;
#include <atcoder/all>
using namespace atcoder;
using mint = modint1000000007;
#include "math/comb.hpp"

int main() {
  int n, l;
  cin >> n >> l;
  // L 段跳びを j 回使う → 移動は全部で n - j*L + j 回、そのうち j 回が L 段跳び
  mint ans = 0;
  for (int j = 0; j * l <= n; j++) ans += comb(n - j * l + j, j);
  cout << ans.val() << '\n';

  // 表が自動で伸びることと、範囲外が 0 になることの確認
  assert(comb(5, 2) == 10 && perm(5, 2) == 20 && homo(3, 2) == 6 && homo(0, 0) == 1);
  assert(comb(3, 4) == 0 && comb(3, -1) == 0 && perm(2, 3) == 0);
  assert(fact(300000) * ifact(300000) == 1);
}
