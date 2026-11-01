#import "lib.typ": contest-conf
#import "statement-common.typ": problem-entry
#let data = json("/" + sys.inputs.at("hull-generated-json-path"))
#show "Problem A. ": none
#show: contest-conf.with(
  title: data.display_name.zh,
  author: "",
  date: "",
  language: "zh",
  enable-titlepage: false,
  problems: (
    problem-entry(data, name => read("zh/" + name + ".typ").trim()),
  ),
)
