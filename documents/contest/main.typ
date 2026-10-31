#import "lib.typ": contest-conf
#import "statement-common.typ": metadata-string
#let data = json("problems.json")
#let section(slug, name) = read(
  "/problems/" + slug + "/zh/" + name + ".typ",
).trim()
#show: contest-conf.with(
  title: data.title,
  subtitle: "试题册",
  author: "",
  date: "",
  language: "zh",
  enable-titlepage: true,
  problems: data.problems.map(p => (
    problem: (
      display_name: p.display_name,
      format: "markup",
      samples: p.samples.map(s => (
        input: s.input.trim(),
        output: s.output.trim(),
      )),
    ),
    statement: (
      description: metadata-string(p.time_seconds, p.memory_mib)
        + section(p.slug, "description"),
      input: section(p.slug, "input"),
      output: section(p.slug, "output"),
      notes: section(p.slug, "note"),
    ),
  )),
)
