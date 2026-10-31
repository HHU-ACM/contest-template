# 出题工作区指南

确保回复为中文。版本管理优先使用 jj；GitHub CI 的只读 Git 查询不受此限制。

## 项目与工具

这是基于 Hull 的比赛模板。涉及 Hull 概念或配置字段时使用 `documentation` skill；新建或大改题目时使用 `author-hull-problems` skill。技能由 `skills-lock.json` 管理，不手改 `.agents/`。

先读 `README.md` 和 `just --list`。`hull`、Python、C++ 编译器和 just 由 `nix develop` 提供；未进入 shell 时命令加 `nix develop --command`。依赖由 `flake.lock` 固定，不为普通出题任务自动升级依赖。

## 入口

```sh
just new array-sum '数组求和'
jj status
just build array-sum
just judge array-sum problems/array-sum/solution/std.20.cpp
just stress array-sum rand independent 100 --n=20 --bound=100 --mode=random
just check
just statements
just previews
just ci
```

`just verify` 为完整验证。Hull 构建执行组件测试、全部测试点和解法预测，是题目的主要验题入口；`just test` 额外检查脚手架、样例副本和 CI 脚本。`just fmt` 格式化，`just check` 要求格式已通过。

## 结构约束

- 题单唯一来源是 `contest.nix`；题目路径写成 `./problems/<slug>/problem.nix`。`-p` 接受目录 slug。题单必须非空，不重复路径。
- `just new` 从独立的 `templates/batch/` 复制，不依赖示例题是否仍存在。不要在修改某道题时顺手改动脚手架。
- 普通题使用 `nix/problem.nix`；`data/samples/*.in` 与 `data/tests/*.in` 自动发现，生成测试通过 `extraTestCases` 注册。没有固定测试时保留 `data/tests/.gitkeep` 以让 Nix 读到该目录。
- 每题有且仅有一个 `mainCorrectSolution = true`；标程、独立解法、错解均声明预期结果。普通工厂默认单个 `sum` 子任务。
- 组件入口保持薄层，解析及判分在每题 `authoring-include/problem.23.hpp`；解法不应依赖 authoring 头文件。
- `.20.cpp` 为 C++20，`.23.cpp` 为 C++23。共用输出比较器忽略行尾空白和末尾空行，保留行首及内部空白。特殊输出需改检查器。
- 新共用头文件必须同步更新 `nix/problem.nix` 的 Hydro `testDataExtraFiles` 与 `judgeExtraFiles`。
- `document/editorial/zh.typ` 自动构建为私有题解。题面四个正文文件在 `document/statement/zh/`，样例在 `samples.json`。
- `samples.json` 与 `data/samples/` 同步修改，`just check` 和预览构建检查一致性；修改题面后重新构建并目视检查 PDF。
- 预览脚本按字面量读取 Nix：标题用字面量字符串，限制用整数或整数乘积；独立配置也需遵守 `documents/README.md` 的约定。
- flake 读取版本库跟踪的文件。新文件先 `jj status`；大数据先设置 `jj config set --repo snapshot.max-new-file-size 8388608`，超过 8 MiB 时提高限制。
- 产物放在忽略的 `.build/`、`.hull/`、`dist/` 或 `result-*` 中。

## CI 和发布

PR 按改动范围验证，`main` 全量验证。`ci` 目标共用一次 runtime analysis 生成内部包与 Hydro 包。私有仓库发版复用同一源码 SHA 的成功产物，缺失时补建一次；公开仓库不上传比赛包或 Release。

默认使用 Actions 缓存；可选 Cachix 必须明确配置名称与可见性，不能沿用其他比赛的缓存。令牌不得写入源码或 derivation。缓存与发布规则见 `documents/ci.md`。

Hydro 导出不等于真实导入成功；导入时检查语言 `cc.cc23o2`、题号及 `owner = 0` 的归属设置。
