#pragma once
#include <bits/stdc++.h>

// 進数変換 (2 <= b <= 36。10 以上の桁は 'A', 'B', ... で表す)
//   to_base(x, b)  : 0 以上の整数 x → b 進数の文字列。例: to_base(10, 2) = "1010"、to_base(0, 9) = "0"
//   from_base(s, b): b 進数の文字列 s → 整数。例: from_base("1010", 2) = 10
// 計算量: O(桁数)
// verify: typical90 067

inline std::string to_base(long long x, int b) {
  if (x == 0) return "0";
  std::string s;
  while (x > 0) {
    int d = x % b;
    s += d < 10 ? '0' + d : 'A' + (d - 10);
    x /= b;
  }
  std::reverse(s.begin(), s.end());
  return s;
}

inline long long from_base(const std::string &s, int b) {
  long long x = 0;
  for (char c : s) {
    int d = isdigit(c) ? c - '0' : toupper(c) - 'A' + 10;
    x = x * b + d;
  }
  return x;
}
