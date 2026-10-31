#import "lib.typ": contest-conf
#import "statement-common.typ": metadata-string
#let language = sys.inputs.at("language", default: "zh")
#let data = json("/" + sys.inputs.at("hull-generated-json-path"))
#let display-name = data.display_name.at(language)
#let section(name) = read(language + "/" + name + ".typ").trim()
#show "Problem A. ": none
#show: contest-conf.with(
  title: display-name,
  author: "",
  date: "",
  language: language,
  enable-titlepage: false,
  problems: (
    (
      problem: (
        display_name: display-name,
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
    ),
  ),
)
