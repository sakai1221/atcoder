// verify: https://atcoder.jp/contests/typical90/tasks/typical90_bo
// test: contest/typical90/bo/test
#include <bits/stdc++.h>
using namespace std;
using ll = long long;
#include <atcoder/all>
using namespace atcoder;
#include "math/base.hpp"

int main() {
  string n;
  int k;
  cin >> n >> k;
  for (int i = 0; i < k; i++) {
    n = to_base(from_base(n, 8), 9);
    for (char &c : n) if (c == '8') c = '5';
  }
  cout << n << '\n';
}
