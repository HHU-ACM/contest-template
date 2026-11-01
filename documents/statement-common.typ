// Shared contest typography and resource-limit display.
#let metadata-string(time-seconds, memory-mib) = (
  "#block(below: 0.5em)[#set text(size: 9pt)\n#grid(columns: (1fr, 1fr, 1fr, 1fr), column-gutter: 1em, [输入文件：标准输入], [输出文件：标准输出], [时间限制："
    + str(time-seconds)
    + " s], [内存限制："
    + str(memory-mib)
    + " MB])]\n\n"
)

// Convert one Hull problem overview to an olymp-in-typst entry.
#let problem-entry(data, section) = (
  problem: (
    display_name: data.display_name.zh,
    format: "markup",
    samples: data.samples.map(sample => (
      input: sample.input.trim(),
      output: sample.outputs.output.trim(),
    )),
  ),
  statement: (
    description: metadata-string(
      data.tick_limit / 10000000000,
      data.memory_limit / 1048576,
    )
      + section("description"),
    input: section("input"),
    output: section("output"),
    notes: section("note"),
  ),
)
