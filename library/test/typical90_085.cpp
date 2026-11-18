// verify: https://atcoder.jp/contests/typical90/tasks/typical90_cg
// test: contest/typical90/cg/test
#include <bits/stdc++.h>
using namespace std;
using ll = long long;
#include <atcoder/all>
using namespace atcoder;
#include "math/int.hpp"
#include "math/prime.hpp"

int main() {
  ll k;
  cin >> k;
  auto d = divisors(k);
  ll ans = 0;
  for (int i = 0; i < (int)d.size(); i++) {
    ll a = d[i];
    if (a > k / a / a) break;  // a^3 > K
    ll m = k / a;
    ll lim = isqrt(m);         // b <= c ⇔ b^2 <= m ⇔ b <= isqrt(m)
    for (int j = i; j < (int)d.size() && d[j] <= lim; j++) {
      if (m % d[j] == 0) ans++;
    }
  }
  cout << ans << '\n';

  // isqrt の境界 (平方数の前後と ll の上限付近)
  for (ll r : {0LL, 1LL, 2LL, 3LL, 999999LL, 1000000LL, 3037000499LL}) {
    assert(isqrt(r * r) == r);
    if (r > 0) assert(isqrt(r * r - 1) == r - 1);
  }
  assert(isqrt(LLONG_MAX) == 3037000499LL);
}
