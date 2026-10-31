#set page(paper: "a4", margin: 24mm)
#set text(
  font: ("FZShuSong-Z01", "New Computer Modern"),
  size: 11pt,
  lang: "zh",
)

= 题解

按顺序读入每个元素，并将其加到初值为 $0$ 的累加器中．

读完前 $i$ 个元素后，累加器等于 $sum_(j=1)^i a_j$．初始时结论成立，每次加上下一个元素后仍成立，因此读完所有元素时得到所求的和．

时间复杂度为 $O(n)$，额外空间复杂度为 $O(1)$．答案的绝对值不超过 $10^12$，使用 64 位整数保存累加结果．实现见 `solution/std.20.cpp`．
