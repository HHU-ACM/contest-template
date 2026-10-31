set positional-arguments
set shell := ["bash", "-eu", "-o", "pipefail", "-c"]

# 列出所有命令。
default:
    @just --list

# 进入含 hull、Python、C++ 编译器和 just 的开发环境。
dev:
    nix develop

# 从独立脚手架新建题目并加入题单：just new array-sum '数组求和'
new slug title:
    nix develop --command python3 scripts/new-problem.py "$1" --title "$2"

# 完整构建并验一道题，可选 target：just build example-sum hydro
build slug target="default":
    nix develop --command hull build -p "$1" -t "$2" -o "result-$1-$2" --interactive never

# 判一份源码：just judge example-sum problems/example-sum/solution/std.20.cpp
judge slug solution:
    nix develop --command hull judge -p "$1" "$2" --interactive never

# 对拍，默认 100 轮：just stress example-sum rand independent 100 --n=20 --bound=100 --mode=random
stress slug generator solution rounds="100" *args:
    nix develop --command hull stress -p "$1" -g "$2" "$3" --rounds "$4" -- "${@:5}"

# 构建整场内部包。
contest:
    nix develop --command hull build-contest -o result-contest --interactive never

# 构建每题的 Hydro ZIP。
hydro:
    nix develop --command hull build-contest -t hydro -o result-hydro --interactive never

# 一次验题，同时生成内部包与 Hydro 包。
ci:
    nix develop --command hull build-contest -t ci -o result-ci --interactive never

# 构建整场题面 PDF。
statements:
    nix build .#contest-statements -o result-statements

# 构建各题独立预览 PDF。
previews:
    nix build .#statement-previews -o result-previews

# 运行脚手架、样例一致性和 CI 回归检查。
test:
    nix develop --command python3 -m unittest discover -s scripts -p 'test_*.py'
    nix develop --command python3 scripts/check_samples.py
    nix develop --command python3 -m unittest discover -s .github/scripts -p 'test_*.py'

# 原地格式化 C++、Nix 和 Typst。
fmt:
    nix fmt

# 轻量检查配置、格式、脚本与样例，不运行 Hull 判题。
check: test
    nix flake check --no-build --no-update-lock-file
    nix fmt -- --ci

# 本地完整验证，与 CI 的全量验题入口一致。
verify: check statements previews ci
