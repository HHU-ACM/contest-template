# 比赛题面

各题使用统一的 `olymp-in-typst` 模板，固定版本为 `3c82fe3dd4ce2540dec6bffcc7ce25f1f20947e6`。模板、字体和 Typst 包由 `nix/statement-resources.nix` 固定，上游许可证保留在 Nix 获取的源中。

```sh
just statements
just previews
```

`result-statements` 是合集 PDF，使用 `contest.nix` 的标题和顺序自动编号；`result-previews/<slug>.pdf` 是各题独立预览。两者不启动 Hull 判题。`just build <slug>` 的正式单题 PDF 使用相同版式，样例输出由 Hull 运行主正确解生成。

正文在各题 `document/statement/zh/` 下的 `description.typ`、`input.typ`、`output.typ`、`note.typ`。预览样例从 `samples.json` 读取，必须与 `data/samples/` 的输入输出按文件名排序逐项一致，组装时会检查。修改样例时两边都要更新。

## 元信息读取约定

`nix/prepare-statements.py` 沿用轻量的正则读取方式，不是完整 Nix 解析器。为支持脚手架与快速预览，配置采用下列约定：

- `contest.nix` 的题单为唯一字面量列表，路径写成 `./problems/<slug>/problem.nix`，不使用注释保存已移除的题目路径。
- 比赛 `displayName.zh` 和题目 `title` 为字面量字符串。
- 普通工厂的 `timeLimitMs`、`memoryLimitMb` 使用整数或整数乘积。
- 独立的 Hull 配置可用字面量 `displayName.zh`、整数或整数乘积的 `tickLimit`、`memoryLimit`。
- 各题使用相同的四个中文正文文件和 `samples.json`。独立配置若更换文档结构，需扩展预览脚本；Hull 单题正式构建仍可独立配置。

时间显示按 `10000000000` ticks 为一秒换算，内存按 `1048576` 字节显示。正文中的插画可放在 `document/statement/illustrations/`，文件名应在比赛内唯一；源路径写成 `/illustrations/<文件名>`。

题解放在 `document/editorial/zh.typ`，共用工厂会自动发现并构建 `editorial.zh.pdf`。它是私有文档，仅进入内部包，Hydro 参赛者题面不包含题解。修改后需检查正式构建的题解 PDF。

提交前重新构建并检查题面、公式、表格、样例和分页。
