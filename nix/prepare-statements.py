#!/usr/bin/env python3
"""Assemble the contest's canonical Typst sections and sample data.

Order and titles/limits come from the contest configuration. Preview samples
are checked against data/samples before rendering.
"""
from __future__ import annotations
import argparse
import json
from pathlib import Path
import re
import shutil
import sys

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / "scripts"))
from check_samples import check_problem


def nix_string_field(source: str, key: str) -> str:
    match = re.search(r"\b" + re.escape(key) + r'\s*=\s*"((?:\\.|[^"\\])*)"\s*;', source)
    if not match:
        raise ValueError(f"Cannot read literal string {key}")
    raw = match[1]
    result = []
    index = 0
    while index < len(raw):
        char = raw[index]
        if char == "\\":
            index += 1
            char = {"n": "\n", "r": "\r", "t": "\t"}.get(raw[index], raw[index])
        elif raw[index:index + 2] == "${":
            raise ValueError(f"String interpolation is not supported for preview field {key}")
        result.append(char)
        index += 1
    return "".join(result)


def numeric_nix_field(source: str, key: str) -> int:
    expression = re.search(r"\b" + key + r"\s*=\s*([\d\s*]+);", source)
    if not expression:
        raise ValueError(f"Cannot read integer product {key}")
    result = 1
    for part in expression[1].split("*"):
        result *= int(part.strip())
    return result


def prepare(output: Path, single: str | None = None) -> list[dict]:
    output.mkdir(parents=True, exist_ok=True)
    contest_source = (ROOT / "contest.nix").read_text()
    slugs = re.findall(r"\./problems/([^/]+)/problem\.nix", contest_source)
    assert slugs and len(slugs) == len(set(slugs)), "Contest problems must be nonempty and distinct"
    if single is not None:
        if single not in slugs:
            raise ValueError(f"Unknown problem: {single}")
        slugs = [single]
    title = nix_string_field(contest_source, "displayName.zh")
    problems = []
    for slug in slugs:
        directory = ROOT / "problems" / slug
        config = (directory / "problem.nix").read_text()
        if 'timeLimitMs' in config:
            name = nix_string_field(config, "title")
            seconds = numeric_nix_field(config, "timeLimitMs") / 1000
            mib = numeric_nix_field(config, "memoryLimitMb")
        else:
            name = nix_string_field(config, "displayName.zh")
            seconds = numeric_nix_field(config, "tickLimit") / 10000000000
            mib = numeric_nix_field(config, "memoryLimit") // 1048576
        statement = directory / "document/statement"
        destination = output / "problems" / slug
        shutil.copytree(statement / "zh", destination / "zh", dirs_exist_ok=True)
        illustrations = statement / "illustrations"
        if illustrations.is_dir():
            shutil.copytree(illustrations, output / "illustrations", dirs_exist_ok=True)
            # Keep the shared destination writable after copying Nix source modes.
            (output / "illustrations").chmod(0o755)
        check_problem(directory)
        samples = json.loads((statement / "samples.json").read_text())
        problems.append({"slug": slug, "display_name": name, "time_seconds": seconds,
                         "memory_mib": mib, "samples": samples})
    entry = "documents/problem-main.typ" if single is not None else "documents/contest/main.typ"
    for source, dest in [(ROOT / entry, "main.typ"),
                         (ROOT / "documents/statement-common.typ", "statement-common.typ")]:
        shutil.copy2(source, output / dest)
    (output / "problems.json").write_text(json.dumps({"title": title, "problems": problems},
                                                      ensure_ascii=False, indent=2) + "\n")
    if single is not None:
        problem = problems[0]
        shutil.copytree(output / "problems" / single / "zh", output / "zh")
        (output / "problem.json").write_text(json.dumps({
            "display_name": {"zh": problem["display_name"]},
            "tick_limit": round(problem["time_seconds"] * 10000000000),
            "memory_limit": problem["memory_mib"] * 1048576,
            "samples": [{"input": sample["input"], "outputs": {"output": sample["output"]}}
                        for sample in problem["samples"]],
        }, ensure_ascii=False, indent=2) + "\n")
    return problems


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--output", type=Path, default=ROOT / ".build/statements")
    parser.add_argument("--single", help="Build one standalone statement preview without judging")
    args = parser.parse_args()
    problems = prepare(args.output.resolve(), args.single)
    print(f"Prepared {len(problems)} statements and {sum(len(p['samples']) for p in problems)} samples in {args.output}")


if __name__ == "__main__":
    main()
