// AI を使って事前に作成したテンプレート・スニペット・ライブラリ: https://github.com/sakai1221/atcoder
#include <bits/stdc++.h>
using namespace std;
using ll = long long;
using ld = long double;
const ll INF = 1LL << 60;  // 約 1.15e18。INF + INF でも溢れない (INF * 大きい数 は溢れる)
const char nl = '\n';

#include <atcoder/all>
using namespace atcoder;
using mint = modint1000000007;  // 998244353 の問題は modint998244353 に変える

#ifdef LOCAL
#include "debug.hpp"
#else
#define debug(...)
#define dassert(...)
#endif

// [スニペット] 打って Tab
// 入力: vin vec gin vvin gr
// 出力: vout yn
// ループ: rep bit bitif dir4
// 全探索: perm comb bt
// 探索: bs lb shaku cycle
// グラフ: dfs bfs bfs01
// 累積: cum cum2 imos imos2
//
// [デバッグ] 手元だけ動く
// debug(x, ...): 中身を表示
// dassert(c, x...): 偽なら停止
//
// [ライブラリ] 下に #include
// math/{comb,int,prime,base}.hpp
// graph/{bfs,tree_diameter}.hpp
// string/rle.hpp

int main() {
  cin.tie(nullptr);
  ios::sync_with_stdio(false);
  cout << fixed << setprecision(15);


  return 0;
}
