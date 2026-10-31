# Contest Template

基于 [Hull](https://hull.aberter0x3f.top/) 的比赛出题模板，提供中文 Typst 题面与题解、CPLib 判题组件、生成器、解法预测、Hydro 导出和 GitHub Actions。工具链及题面资源沿用固定版本，依赖记录在 `flake.lock`。

## 开始使用

安装启用 flakes 的 Nix。使用 GitHub 的 **Use this template** 创建自己的仓库，或复制本模板后初始化新的仓库。使用 jj 时：

```sh
jj git init --colocate
jj config set --repo snapshot.max-new-file-size 8388608
nix develop
just                    # 查看命令
just verify             # 完整验证示例、题面与两种比赛包
```

这份本地模板已经初始化为独立的 jj/Git colocated 仓库。新建比赛后先修改 `contest.nix` 的 `name` 和 `displayName.zh`，再调整题单。`name` 使用 camelCase，题目录名使用 kebab-case。默认主分支名为 `main`；若使用其他名称，需同步修改 `.github/workflows/check.yml` 的 push 分支。

`problems/example-sum/` 是可删除的数列求和示例。删除它时也要从 `contest.nix` 移除对应路径，并保证题单至少保留一道题。示例包含两份正确实现、一份错解、样例、定向数据、五种生成模式和私有题解。新题脚本使用独立的 `templates/batch/`，删除示例不影响后续开题。

## 新建题目

```sh
just new array-sum '数组求和'
# 等价：nix develop --command python3 scripts/new-problem.py array-sum --title '数组求和'
jj status               # jj 快照纳入新文件，供 Git flake 读取
just build array-sum
```

脚本创建完整目录，设置 `name = "arraySum"` 和中文标题，并追加到 `contest.nix`。已有路径、重复机器标识和不支持的题单写法会报错，不覆盖已有题目。生成后仍是数列求和内容：需要一起修改题意、标程、校验器、检查器、生成器、数据、样例、题解、范围和错解预测。

在 `nix develop` 中使用命令可避免系统缺少 Python 或 just；不进入 shell 时，也可以运行 `nix develop --command just <命令>`。新文件超过 jj 的默认 1 MiB 限制时会被拒收，应先设置上述仓库配置；超过 8 MiB 时相应调高。纯 Git 工作区需用 `git add` 纳入新增文件。

## 常用命令

| 命令 | 用途 |
| --- | --- |
| `just build example-sum` | 单题完整验证与内部打包 |
| `just build example-sum hydro` | 单题 Hydro 打包 |
| `just judge example-sum problems/example-sum/solution/std.20.cpp` | 判指定源码，无需预先注册解法 |
| `just stress example-sum rand independent 100 --n=20 --bound=100 --mode=random` | 运行 100 轮生成器对拍；Hull 自动注入每组 salt |
| `just contest` / `just hydro` | 整场内部包 / 每题 Hydro ZIP |
| `just ci` | 一次验题，同时构建内部包和 Hydro 包 |
| `just statements` / `just previews` | 合集 PDF / 各题独立预览，不启动判题 |
| `just fmt` | 格式化 C++、Nix、Typst |
| `just test` / `just check` | 脚本及样例检查 / 加上配置与格式检查 |
| `just verify` | 完整本地验证 |

输出在忽略的 `result-*` 链接中：`result-statements` 为合集 PDF，`result-previews/` 为独立预览，`result-ci/internal/` 和 `result-ci/hydro/` 为联合构建结果。`hull` 的 `-p` 接受目录 slug，而不是 `problem.nix` 的机器标识。

## 目录与约定

- `contest.nix`：比赛标题、唯一题单及其顺序，合集编号随题单顺序产生。
- `nix/problem.nix`：普通批处理题工厂，按目录发现固定测试，支持 `extraTestCases` 注册生成数据，以及组件测试与生成器。
- `templates/batch/`：新题脚手架，不注册为比赛题目；修改它只影响以后新建的题。
- `problems/<slug>/`：题目配置、组件、解法、数据及 Typst 源码。
- `authoring-include/`：共用输出比较器；每题的输入模型和校验逻辑放在自己的 `authoring-include/problem.23.hpp`。
- `documents/`、`nix/`：固定题面资源、合集与单题构建模块。
- `.agents/`、`skills-lock.json`：随模板保留的 Hull 出题技能及锁定来源，不手改技能内容。

每题有且仅有一个 `mainCorrectSolution = true`。正式答案由主正确解生成；`data/tests/` 只需 `.in`。`data/samples/` 的每个 `.in` 都应有 `.out`，并与 `document/statement/samples.json` 按文件名排序逐项一致。`just check` 和题面构建会检查这两份样例副本；输出是否正确仍由 Hull 验证。

默认检查器忽略行尾空白和末尾空行，保留行首及内部空白，不适用于多解、浮点容差等特殊判题。解法沿用 C++20，组件为 C++23，标准由 `.20.cpp`、`.23.cpp` 后缀决定。默认一个按测试点求和的子任务，满分 `1.0`。新增共用头文件时需同步维护 Hydro 的 `testDataExtraFiles` 和 `judgeExtraFiles`。

首版脚手架只覆盖普通批处理题。特殊检查器可修改本题共享头文件；复杂子任务和交互题可编写独立的 Hull `problem.nix`，不必使用共用工厂。题面预览的元信息读取约定、独立配置的限制见 [题面说明](documents/README.md)。

## CI、缓存与导出

保留 PR 增量验证、默认分支全量验证、Wasmtime 编译缓存、联合打包及标签发布复用。默认使用 GitHub Actions 的 Nix store 缓存，不配置公共 Cachix、不主动上传到外部缓存。可选 Cachix 需自行选择缓存及其可见性，并设置 `CACHIX_CACHE` 和 `CACHIX_AUTH_TOKEN`。设置后会缓存构建产物及依赖闭包，其中包含题面、数据和标程。详细行为见 [CI 说明](documents/ci.md)。

公开仓库仅执行验证；内部包与 Hydro 包的 Actions artifact 上传及 Release 仅在私有仓库启用。新仓库无需已有 artifact，首次全量构建会生成；在 `main` 上的已验证提交推送 `v*` 标签可触发发布。远端与仓库 Template 标记需要在 GitHub 自行设置，本模板不绑定组织、远端或上传凭据。

Hydro 目标默认 `owner = 0`，组件语言使用 `cc.cc23o2`。目标实例需启用对应语言，导入时检查题号和归属。本地导出验证不替代真实实例的导入测试。
