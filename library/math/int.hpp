#pragma once
#include <bits/stdc++.h>

// 整数演算 (浮動小数点・オーバーフローを避ける)
//   ipow(a, e)         : a^e (e >= 0)。結果が long long に収まる場合だけ使う
//                        pow() は double なので大きい値で誤差が出る → 整数で比べたいときはこちら
//   mul_over(a, b, lim): a * b > lim か (a, b, lim >= 0)。a * b を計算せずに判定する
//   lcm_over(a, b, lim): lcm(a, b) > lim か (a, b >= 1, lim >= 0)。lcm を計算せずに判定する
//                        超えないと分かったら lcm は a / gcd(a, b) * b で計算する (先に割る)
//   isqrt(n)           : floor(√n) (n >= 0)。sqrt() は double なので大きい n で ±1 ずれることがある
//                        「d * d <= n の間ループ」の上限や、平方数の判定 (isqrt(n) * isqrt(n) == n) に
// 計算量: ipow は O(log e)、mul_over は O(1)、lcm_over は O(log) (gcd)、isqrt は O(1)
// verify: typical90 020 (ipow), 038 (mul_over, lcm_over), 085 (isqrt)

inline long long ipow(long long a, long long e) {
  long long res = 1;
  while (e > 0) {
    if (e & 1) res *= a;
    e >>= 1;
    if (e > 0) a *= a;
  }
  return res;
}

inline bool mul_over(long long a, long long b, long long lim) {
  if (a == 0 || b == 0) return false;
  return a > lim / b;
}

inline bool lcm_over(long long a, long long b, long long lim) {
  return mul_over(a / std::gcd(a, b), b, lim);
}

inline long long isqrt(long long n) {
  assert(n >= 0);
  long long r = std::sqrt((long double)n);
  // 誤差の補正。r * r は溢れることがあるので割り算で比べる
  while (r > 0 && r > n / r) r--;
  while (r + 1 <= n / (r + 1)) r++;
  return r;
}
