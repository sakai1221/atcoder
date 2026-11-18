// verify: https://atcoder.jp/contests/typical90/tasks/typical90_cf
// test: contest/typical90/cf/test
#include <bits/stdc++.h>
using namespace std;
using ll = long long;
#include <atcoder/all>
using namespace atcoder;
#include "string/rle.hpp"

int main() {
  ll n;
  string s;
  cin >> n >> s;
  ll ans = n * (n + 1) / 2;
  for (auto [c, k] : rle(s)) ans -= k * (k + 1) / 2;
  cout << ans << '\n';
}
