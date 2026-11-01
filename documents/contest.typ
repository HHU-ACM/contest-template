#import "lib.typ": contest-conf
#import "statement-common.typ": problem-entry
#let data = json("/" + sys.inputs.at("hull-generated-json-path"))
#show: contest-conf.with(
  title: data.display_name.zh,
  subtitle: "试题册",
  author: "",
  date: "",
  language: "zh",
  enable-titlepage: true,
  problems: data
    .problems
    .enumerate()
    .map(((index, problem)) => problem-entry(
      problem,
      name => read(
        "/problems/" + str(index) + "/" + name + ".typ",
      ).trim(),
    )),
)
