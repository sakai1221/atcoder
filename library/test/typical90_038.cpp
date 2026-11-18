// verify: https://atcoder.jp/contests/typical90/tasks/typical90_al
// test: contest/typical90/al/test
#include <bits/stdc++.h>
using namespace std;
using ll = long long;
#include <atcoder/all>
using namespace atcoder;
#include "math/int.hpp"

int main() {
  ll a, b;
  cin >> a >> b;
  // mul_over を直接使う版と lcm_over 版が一致することも確認する
  ll x = a / gcd(a, b);
  bool over = lcm_over(a, b, (ll)1e18);
  assert(over == mul_over(x, b, (ll)1e18));
  if (over) cout << "Large" << '\n';
  else cout << x * b << '\n';
}
