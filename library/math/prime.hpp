#pragma once
#include <bits/stdc++.h>

// 素因数分解・約数列挙・エラトステネスの篩
//   factorize(n): {素数, 指数} の列 (素数の昇順)。例: 12 → {{2, 2}, {3, 1}}。n = 1 なら空
//   divisors(n) : n の約数を昇順で。例: 12 → {1, 2, 3, 4, 6, 12}
//   sieve(n)    : is_prime[i] (0 <= i <= n) が i が素数かどうか
// 計算量: factorize / divisors は O(√n) (n <= 1e12 くらいまで)、sieve は O(n log log n)
// verify: typical90 075 (factorize)

inline std::vector<std::pair<long long, int>> factorize(long long n) {
  std::vector<std::pair<long long, int>> res;
  for (long long p = 2; p * p <= n; p++) {
    if (n % p != 0) continue;
    int e = 0;
    while (n % p == 0) {
      n /= p;
      e++;
    }
    res.push_back({p, e});
  }
  if (n > 1) res.push_back({n, 1});
  return res;
}

inline std::vector<long long> divisors(long long n) {
  std::vector<long long> small, large;
  for (long long d = 1; d * d <= n; d++) {
    if (n % d != 0) continue;
    small.push_back(d);
    if (d != n / d) large.push_back(n / d);
  }
  small.insert(small.end(), large.rbegin(), large.rend());
  return small;
}

inline std::vector<bool> sieve(int n) {
  std::vector<bool> is_prime(n + 1, true);
  is_prime[0] = false;
  if (n >= 1) is_prime[1] = false;
  for (long long i = 2; i * i <= n; i++) {
    if (!is_prime[i]) continue;
    for (long long j = i * i; j <= n; j += i) is_prime[j] = false;
  }
  return is_prime;
}
