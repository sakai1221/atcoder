// verify: https://atcoder.jp/contests/typical90/tasks/typical90_bw
// test: contest/typical90/bw/test
#include <bits/stdc++.h>
using namespace std;
using ll = long long;
#include <atcoder/all>
using namespace atcoder;
#include "math/prime.hpp"

int main() {
  ll n;
  cin >> n;
  int cnt = 0;
  for (auto [p, e] : factorize(n)) cnt += e;
  int ans = 0;
  while ((1 << ans) < cnt) ans++;
  cout << ans << '\n';
}
