"""Create a buildable batch problem and register it in contest.nix."""
from __future__ import annotations

import argparse
import json
from pathlib import Path
import re
import shutil
import tempfile

ROOT = Path(__file__).resolve().parents[1]
SLUG = re.compile(r"[a-z][a-z0-9]*(?:-[a-z0-9]+)*\Z")


def nix_string(value: str) -> str:
    return json.dumps(value, ensure_ascii=False).replace("${", r"\${")


def create(root: Path, slug: str, title: str) -> Path:
    if not SLUG.fullmatch(slug):
        raise ValueError("slug 必须为小写字母开头的 kebab-case，如 array-sum")
    if not title.strip() or any(ord(c) < 32 or ord(c) == 127 for c in title):
        raise ValueError("标题不能为空或包含控制字符")
    parts = slug.split("-")
    name = parts[0] + "".join(word[0].upper() + word[1:] for word in parts[1:])
    destination = root / "problems" / slug
    if destination.exists() or destination.is_symlink():
        raise ValueError(f"目标已存在，拒绝覆盖：{destination}")
    contest_file = root / "contest.nix"
    original = contest_file.read_text()
    lists = list(re.finditer(r"\bproblems\s*=\s*\[(?P<body>[^\]]*)\];", original))
    if len(lists) != 1:
        raise ValueError("contest.nix 必须包含唯一的字面量 problems = [ ... ]; 列表")
    problem_list = lists[0]
    paths = re.findall(r"\./problems/([^/]+)/problem\.nix", problem_list["body"])
    for other in paths:
        source = (root / "problems" / other / "problem.nix").read_text()
        match = re.search(r'^\s*name\s*=\s*"([^\"]+)";', source, re.M)
        if other == slug or (match and match[1] == name):
            raise ValueError(f"题目录径或机器标识冲突：{other} / {name}")
    line_start = original.rfind("\n", 0, problem_list.end() - 2) + 1
    if original[line_start:problem_list.end() - 2].strip():
        # A compact one-line list is valid too.
        line_start = problem_list.end() - 2
        prefix = "\n"
    else:
        prefix = ""
    updated = (original[:line_start] + prefix + f"    ./problems/{slug}/problem.nix\n"
               + original[line_start:])
    destination.parent.mkdir(parents=True, exist_ok=True)
    with tempfile.TemporaryDirectory(prefix=".new-problem-", dir=root / "problems") as temp:
        staged = Path(temp) / slug
        shutil.copytree(root / "templates/batch", staged,
                        ignore=shutil.ignore_patterns("__pycache__", "*.pyc"))
        config = staged / "problem.nix"
        source = config.read_text()
        for key, value in (("name", name), ("title", title)):
            source, count = re.subn(rf'(?m)^(  {key}\s*=\s*)"[^\"]*";',
                                    lambda m: m[1] + nix_string(value) + ";", source)
            if count != 1:
                raise ValueError(f"脚手架中 {key} 字段必须恰好出现一次")
        config.write_text(source)
        staged.rename(destination)
        try:
            # Refuse to overwrite an edit made while the scaffold was copied.
            if contest_file.read_text() != original:
                raise ValueError("contest.nix 已被其他进程修改，请重试")
            contest_file.write_text(updated)
        except BaseException:
            shutil.rmtree(destination)
            raise
    return destination


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("slug")
    parser.add_argument("--title", required=True)
    args = parser.parse_args()
    try:
        destination = create(ROOT, args.slug, args.title)
    except (ValueError, OSError) as error:
        parser.exit(1, f"创建失败：{error}\n")
    print(f"已创建 {destination} 并加入 contest.nix。")
    print("当前内容仍为数列求和示例；请一起修改题面、程序、范围、数据和预测。")
    print(f"使用 jj 时先运行 jj status 纳入新文件，再运行 just build {args.slug}。")


if __name__ == "__main__":
    main()
