# ランダム入力ジェネレータ。`r` が `python3 gen.py <seed>` として何度も呼ぶ。
# 問題の「入力」形式どおりに標準出力へ出力するように書き換える。
#
# コツ:
#   - 落ちるケースを探すなら、値は小さく (N <= 5, 値 <= 10 など)。
#     小さいほうがバグの再現ケースが読みやすい。
#   - TLE チェックなら制約の上限まで大きくする。
import random
import sys

random.seed(int(sys.argv[1]))

# ---- 例: 1 行目に N、2 行目に N 個の整数 (1 <= A_i <= 10) ----
n = random.randint(1, 5)
a = [random.randint(1, 10) for _ in range(n)]
print(n)
print(*a)
