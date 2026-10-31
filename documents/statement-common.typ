// Shared contest typography and resource-limit display.
#let metadata-string(time-seconds, memory-mib) = (
  "#block(below: 0.5em)[#set text(size: 9pt)\n#grid(columns: (1fr, 1fr, 1fr, 1fr), column-gutter: 1em, [输入文件：标准输入], [输出文件：标准输出], [时间限制："
    + str(time-seconds)
    + " s], [内存限制："
    + str(memory-mib)
    + " MB])]\n\n"
)
