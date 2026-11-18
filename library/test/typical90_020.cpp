// verify: https://atcoder.jp/contests/typical90/tasks/typical90_t
// test: contest/typical90/t/test
#include <bits/stdc++.h>
using namespace std;
using ll = long long;
#include <atcoder/all>
using namespace atcoder;
#include "math/int.hpp"

int main() {
  ll a, b, c;
  cin >> a >> b >> c;
  cout << (a < ipow(c, b) ? "Yes" : "No") << '\n';
}
