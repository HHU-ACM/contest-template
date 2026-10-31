"""Check that preview samples match the files used by Hull."""
from __future__ import annotations

import argparse
import json
from pathlib import Path
import re

ROOT = Path(__file__).resolve().parents[1]


def problem_slugs(root: Path) -> list[str]:
    slugs = re.findall(r"\./problems/([^/]+)/problem\.nix", (root / "contest.nix").read_text())
    if not slugs or len(set(slugs)) != len(slugs):
        raise ValueError("contest.nix 的题目列表必须非空且不能重复")
    return slugs


def check_problem(directory: Path) -> None:
    folder = directory / "data/samples"
    inputs = sorted(folder.glob("*.in"))
    if not inputs or {p.stem for p in inputs} != {p.stem for p in folder.glob("*.out")}:
        raise ValueError(f"{directory.name}: 样例 .in 和 .out 必须非空且一一配对")
    expected = [{"input": p.read_text(), "output": p.with_suffix(".out").read_text()}
                for p in inputs]
    actual = json.loads((directory / "document/statement/samples.json").read_text())
    if actual != expected:
        raise ValueError(f"{directory.name}: samples.json 与 data/samples/ 内容或排序不一致")


def check(root: Path) -> None:
    for slug in problem_slugs(root):
        check_problem(root / "problems" / slug)


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--root", type=Path, default=ROOT)
    args = parser.parse_args()
    check(args.root)
    print("样例副本检查通过")


if __name__ == "__main__":
    main()
