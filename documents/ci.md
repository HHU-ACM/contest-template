# CI、缓存与发布

## 验证范围

PR 以 base 与 head 的 merge base 计算改动；重命名同时检查旧、新路径。`.github/scripts/plan.py` 根据路径选择工作：

| 改动 | 验证 |
| --- | --- |
| 题面 Typst、插画、共用题面模板 | 合集与独立预览，不启动 Hull 判题 |
| 样例、解法、组件、生成器、题解、单题配置 | 对应题目的完整 Hull 验证 |
| 共用组件、Nix 模块、锁文件、题单、CI、新题脚本、脚手架或未知构建输入 | 全量验证 |
| 仓库说明与 agent 指南 | 格式和 flake 配置检查 |

每次规划前执行脚手架、样例一致性及 CI 脚本回归检查。`main` push 和手动构建始终全量验证。工作流默认主分支为 `main`，创建仓库后若修改默认分支名，也应修改 `check.yml` 的 push 分支。

`contest.nix` 的 `ci` 目标在一次 runtime analysis 后同时生成两种比赛包：

```sh
just ci
```

输出为 `result-ci/internal/` 与 `result-ci/hydro/`。本地检查可用 `just verify`；GitHub 工作流另外负责缓存、打包与上传。

## 默认缓存

未设置 `CACHIX_CACHE` 时，使用 GitHub Actions 的 Nix store 缓存。键含 lock hash 和源码提交，恢复最近兼容缓存，保存前清理上限为 12 GiB，profile 保留构建环境。默认不连接 Cachix，也没有预设组织或比赛缓存名。

Wasmtime 本机编译缓存独立于 Nix store，通过 `HULL_WASMTIME_CACHE_DIR` 指定，按系统、架构、锁文件和提交保存。Hull 校验模块内容及引擎兼容性；不兼容时重新编译。只有成功的非 PR 构建保存编译缓存，PR 仅读取；纯题面构建不恢复这份缓存。

缓存也可能包含题目内容；题目未公开时应使用私有比赛仓库，并按 GitHub 的缓存访问规则管理仓库权限。

## 按需启用 Cachix

先选择缓存及其可见性，再配置 Actions Variable `CACHIX_CACHE` 和具有写权限的 Secret `CACHIX_AUTH_TOKEN`。该模式缓存项目输出及其依赖闭包，包括题面、测试数据和标程，公共缓存意味着这些内容可公开获取。无写令牌时工作流只尝试读取，私有缓存的读取权限需按 Cachix 配置处理。令牌不得写入源码或 derivation。

预热脚本没有默认上传目的地，必须传入 `--cache` 或显式设置环境变量 `CACHIX_CACHE`：

```sh
nix develop --command python3 .github/scripts/seed_cache.py --cache YOUR_CACHE --list-only
nix develop --command python3 .github/scripts/seed_cache.py --cache YOUR_CACHE
```

脚本只选择项目构建环境、runtime 元数据中的已构建程序及 `result-*` 的依赖闭包，不遍历整个本机 Nix store。上传用令牌由环境变量读取，或在终端隐藏输入，不落盘。入口路径列表保存到忽略的 `.build/cachix-seed-paths.txt`。模板不会自动执行此脚本。

## Artifact 与发版

公开仓库仅验证，不上传内部包、Hydro 包或发布 Release。私有仓库全量验证会生成保留 14 天的 `contest-packages-<源码 SHA>`，其 `manifest.json` 记录提交和每个文件的 SHA-256。

向默认分支上的已验证提交推送 `v*` 标签可触发发布。发布流程只复用 `check.yml` 中成功的默认分支 push 或明确指定提交的手动构建产物，不使用 PR 产物。仍在验证则等待，验证失败则终止；产物缺失或过期时，通过默认分支 `workflow_dispatch` 补建指定 SHA 一次，再校验清单及标签是否移动。

发布附件为合集 PDF、内部包和所有 Hydro ZIP。可手动重试已有标签：

```sh
gh workflow run release.yml -f tag=v1.0.0
```

模板保留这些工作流，但没有绑定 GitHub 远端。实际 Actions 缓存、artifact 和 Release 需要在创建远端仓库后运行验证。
