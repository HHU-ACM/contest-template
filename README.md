# Contest Template

基于 [Hull](https://hull.aberter0x3f.top/) 的最小比赛出题模板：中文 Typst 题面与题解、CPLib 判题组件、解法预测、合集 PDF 和 Hydro 导出。依赖由 `flake.lock` 固定。

## 开始使用

安装启用 flakes 的 Nix，用本模板创建仓库后进入开发环境。以下命令都在 `nix develop` 中运行：

```sh
hull build-contest
```

然后修改 `contest.nix` 的 `name` 和 `displayName.zh`。

## 新建题目

```sh
cp -r problems/exampleSum problems/arraySum
```

目录名就是题目的机器名，使用 camelCase。之后：

1. 修改新题 `problem.nix` 的 `displayName.zh`。
2. 把 `./problems/arraySum/problem.nix` 加入 `contest.nix`，题号按列表顺序产生。
3. 运行 `jj status` 纳入新文件，flake 只读取版本库跟踪的文件。
4. 修改题面、程序、数据、范围、组件测试和解法预测。

大文件超过 jj 的 1 MiB 限制时，先运行 `jj config set --repo snapshot.max-new-file-size 8388608`。

## 常用命令

| 命令 | 用途 |
| --- | --- |
| `hull build -p arraySum` | 验一道题，`-t hydro` 构建 Hydro 包 |
| `hull judge -p arraySum <源码>` | 判一份源码，无需注册解法 |
| `hull stress -p arraySum -g rand independent --rounds 100 -- --n=20 --bound=100 --mode=random --salt=x` | 对拍 |
| `hull build-contest` | 验全部题目并生成比赛产物 |
| `nix fmt` | 格式化 C++、Nix、Typst；`nix fmt -- --ci` 只检查 |

`hull build-contest` 的输出在 `result/`：`internal/` 是内部包，`hydro/<name>` 是 Hydro 的 ZIP，`statements.pdf` 是合集。

## 目录

```
contest.nix          比赛标题、题单和产物
nix/problem.nix      批处理题的共享默认值
nix/documents.nix    Typst 工具链，题面、题解和合集的构建
documents/           题面版式入口
problems/<name>/     题目；exampleSum 是示例
```

每题的 `problem.nix` 使用标准 Hull 字段，并导入 `nix/problem.nix`。共享模块按 `data/samples/*.in` 和 `data/tests/*.in` 发现测试点，并提供默认的文档和 target。各题可以直接覆盖，例如用自己的 `subtasks` 配置子任务。

题面正文在 `document/statement/zh/` 的 `description.typ`、`input.typ`、`output.typ`、`note.typ`。插画放在 `document/statement/illustrations/`，用 `/illustrations/<文件名>` 引用，文件名在比赛内保持唯一。题解在 `document/editorial/zh.typ`，只进入内部包。题面中的样例由 Hull 运行主正确解生成，所以构建 PDF 需要先通过验题。

检查器在每题的 `authoring-include/problem.23.hpp` 中解析输出。`.20.cpp` 为 C++20，`.23.cpp` 为 C++23。

Hydro 使用原生导出，默认 `owner = 0`，组件语言为 `cc.cc23o2`。本地导出成功不等于导入成功，导入时检查语言、题号和归属。
