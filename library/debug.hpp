#pragma once
// Debug output to stderr, for local builds only.
// template.cpp includes this under `#ifdef LOCAL` (only the local build passes -DLOCAL),
// so on AtCoder `debug(...)` expands to nothing and this file is not needed.
//
//   debug(x);            // [L12] x = 5
//   debug(v, st, mp);    // [L13] v = [1, 2, 3] | st = {1, 2} | mp = {1: 10, 2: 20}
//
//   dassert(0 <= p && p < n);        // false なら行番号と条件式を表示して止まる (RE)
//   dassert(len > 0, i, a[n], len);  // 止まるときに、後ろの変数の中身も表示する
//   (手元専用。提出時は template.cpp の #else で何もしないマクロになる)
//
// Prints numbers, bool, char, strings, pair/tuple, any range (vector, set, map, ...)
// nested to any depth, queue/stack/priority_queue, and atcoder::modint (via .val()).
#include <bits/stdc++.h>

namespace dbg {

template <class T>
void print(std::ostream& os, const T& x);

template <class T>
concept Streamable = requires(std::ostream& os, const T& x) { os << x; };
template <class T>
concept TupleLike = requires { std::tuple_size<T>::value; };
template <class T>
concept MapLike = std::ranges::range<T> && requires { typename T::key_type; typename T::mapped_type; };
template <class T>
concept SetLike = std::ranges::range<T> && requires { typename T::key_type; };
template <class T>
concept HasVal = requires(const T& x) { x.val(); };  // atcoder::modint etc.
template <class T>
concept HasTop = requires(T x) { x.top(); x.pop(); x.empty(); };  // stack, priority_queue
template <class T>
concept HasFront = requires(T x) { x.front(); x.pop(); x.empty(); };  // queue

template <class T>
void print(std::ostream& os, const T& x) {
  if constexpr (std::is_same_v<T, bool>) {
    os << (x ? "true" : "false");
  } else if constexpr (std::is_same_v<T, char>) {
    os << '\'' << x << '\'';
  } else if constexpr (std::is_convertible_v<const T&, std::string_view>) {
    os << '"' << std::string_view(x) << '"';
  } else if constexpr (std::is_same_v<T, __int128> || std::is_same_v<T, unsigned __int128>) {
    if (x == 0) { os << '0'; return; }
    std::string s;
    bool neg = x < 0;
    unsigned __int128 u = neg ? -(unsigned __int128)x : (unsigned __int128)x;
    while (u > 0) { s += char('0' + u % 10); u /= 10; }
    if (neg) s += '-';
    std::reverse(s.begin(), s.end());
    os << s;
  } else if constexpr (Streamable<T>) {
    os << x;
  } else if constexpr (HasVal<T>) {
    os << x.val();
  } else if constexpr (TupleLike<T>) {
    os << '(';
    std::apply([&](const auto&... e) {
      int i = 0;
      ((os << (i++ ? ", " : ""), print(os, e)), ...);
    }, x);
    os << ')';
  } else if constexpr (MapLike<T>) {
    os << '{';
    bool first = true;
    for (const auto& [k, v] : x) {
      os << (first ? "" : ", ");
      print(os, k);
      os << ": ";
      print(os, v);
      first = false;
    }
    os << '}';
  } else if constexpr (std::ranges::range<T>) {
    os << (SetLike<T> ? '{' : '[');
    bool first = true;
    for (const auto& e : x) {
      os << (first ? "" : ", ");
      print(os, e);
      first = false;
    }
    os << (SetLike<T> ? '}' : ']');
  } else if constexpr (HasTop<T> || HasFront<T>) {
    T c = x;  // copy, then pop everything
    os << '[';
    bool first = true;
    while (!c.empty()) {
      os << (first ? "" : ", ");
      if constexpr (HasTop<T>) print(os, c.top());
      else print(os, c.front());
      c.pop();
      first = false;
    }
    os << ']';
  } else {
    static_assert(sizeof(T) == 0, "debug: don't know how to print this type");
  }
}

// Split "a, f(b, c), v[{1, 2}]" into {"a", "f(b, c)", "v[{1, 2}]"}.
inline std::vector<std::string> split_names(std::string_view s) {
  std::vector<std::string> res;
  std::string cur;
  int depth = 0;
  char quote = 0;
  for (size_t i = 0; i < s.size(); i++) {
    char c = s[i];
    if (quote) {
      cur += c;
      if (c == '\\' && i + 1 < s.size()) cur += s[++i];
      else if (c == quote) quote = 0;
      continue;
    }
    if (c == '"' || c == '\'') quote = c;
    else if (c == '(' || c == '[' || c == '{') depth++;
    else if (c == ')' || c == ']' || c == '}') depth--;
    else if (c == ',' && depth == 0) {
      res.push_back(cur);
      cur.clear();
      continue;
    }
    if (!(cur.empty() && c == ' ')) cur += c;
  }
  res.push_back(cur);
  return res;
}

template <class... Ts>
void debug_impl(int line, std::string_view names, const Ts&... xs) {
  auto ns = split_names(names);
  std::ostringstream os;
  os << "[L" << line << "] ";
  int i = 0;
  ((os << (i ? " | " : "") << ns[i] << " = ", print(os, xs), i++), ...);
  std::cerr << os.str() << std::endl;
}

template <class... Ts>
void dassert_impl(int line, const char* cond_str, bool ok, std::string_view names, const Ts&... xs) {
  if (ok) return;
  std::cerr << "[L" << line << "] dassert failed: " << cond_str << std::endl;
  if constexpr (sizeof...(xs) > 0) debug_impl(line, names, xs...);
  std::abort();
}

}  // namespace dbg

#define debug(...) dbg::debug_impl(__LINE__, #__VA_ARGS__, __VA_ARGS__)
#define dassert(cond, ...) \
  dbg::dassert_impl(__LINE__, #cond, static_cast<bool>(cond), #__VA_ARGS__ __VA_OPT__(, ) __VA_ARGS__)
