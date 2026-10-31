"""Select PR verification work; unknown build inputs require full verification."""
import argparse
import json
from pathlib import Path
import re
import subprocess


def plan(paths, slugs, full=False):
    selected = set()
    render = full
    reasons = []
    for path in paths:
        parts = Path(path).parts
        if len(parts) > 2 and parts[0] == "problems":
            slug = parts[1]
            if slug not in slugs:
                full = True
                reasons.append(f"added or removed problem: {slug}")
            elif (parts[2:4] == ("document", "statement")
                  and path.endswith((".typ", ".png", ".svg", ".jpg", ".jpeg", ".webp"))):
                render = True
            else:
                selected.add(slug)
                render = True
        elif path.startswith("documents/"):
            render |= path.endswith((".typ", ".png", ".svg", ".jpg", ".jpeg", ".webp"))
        elif (path.endswith(".md") or path.startswith((".agents/", ".claude/"))
              or path == "skills-lock.json"):
            continue
        else:
            full = True
            reasons.append(f"shared or unrecognized input: {path}")
    return {
        "full": full,
        "problems": sorted(slugs if full else selected),
        "statements": render or full,
        "reason": "; ".join(reasons) or ("full verification" if full else "changed files"),
    }


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--base")
    parser.add_argument("--head")
    parser.add_argument("--full", action="store_true")
    parser.add_argument("--output", required=True)
    args = parser.parse_args()
    slugs = re.findall(r"\./problems/([^/]+)/problem\.nix", Path("contest.nix").read_text())
    if not slugs or len(slugs) != len(set(slugs)):
        raise ValueError("Invalid contest problem list")
    paths = []
    if not args.full:
        if not args.base or not args.head:
            parser.error("PR verification needs base and head commits")
        changed = subprocess.check_output([
            "git", "diff", "--no-renames", "--name-only", "-z",
            f"{args.base}...{args.head}", "--",
        ])
        paths = [p.decode() for p in changed.split(b"\0") if p]
    result = plan(paths, slugs, args.full)
    with open(args.output, "a") as output:
        for key, value in result.items():
            if key == "reason":
                continue
            output.write(f"{key}={value if isinstance(value, str) else json.dumps(value)}\n")
    print(json.dumps(result, ensure_ascii=False, indent=2))


if __name__ == "__main__":
    main()
