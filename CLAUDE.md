# 出题工作区指南

确保回复为中文。版本管理优先使用 jj。

## 项目与工具

这是基于 Hull 的比赛模板。涉及 Hull 概念或配置字段时使用 `documentation` skill；新建或大改题目时使用 `author-hull-problems` skill。技能由 `skills-lock.json` 管理，不手改 `.agents/`。

先读 `README.md`。工具由 `nix develop` 提供，未进入 shell 时命令加 `nix develop --command`。依赖由 `flake.lock` 固定，不为普通出题任务自动升级依赖。

## 结构约束

- 题单唯一来源是 `contest.nix`，题目路径写成 `./problems/<name>/problem.nix`。
- 目录名就是题目机器名，使用 camelCase，不在 `problem.nix` 中另设 `name`。
- 每题 `problem.nix` 用标准 Hull 字段并导入 `nix/problem.nix`；特殊题直接覆盖共享默认值，不给模块加参数。
- 每题有且仅有一个 `mainCorrectSolution = true`；所有解法声明预期结果。
- 组件测试写在各题 `problem.nix`；组件入口保持薄层，解析及判分在每题 `authoring-include/problem.23.hpp`；解法不依赖 authoring 头文件。
- flake 读取版本库跟踪的文件，新文件先 `jj status`。
- 提交前运行 `nix fmt` 和 `hull build-contest`；修改题面后目视检查 PDF。
- 产物放在忽略的 `.build/`、`.hull/` 或 `result*` 中。

Hydro 导出不等于真实导入成功；导入时检查语言 `cc.cc23o2`、题号及 `owner = 0` 的归属设置。
