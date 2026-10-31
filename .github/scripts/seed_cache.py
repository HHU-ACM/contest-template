"""Push this project's already-built toolchain and outputs without persisting a token."""
import argparse
import getpass
import json
import os
from pathlib import Path
import re
import subprocess


def command(*args):
    return subprocess.check_output(args, text=True).strip()


def store_root(value):
    match = re.match(r"(/nix/store/[a-z0-9]{32}-[^/]+)(?:/|$)", str(value))
    return match[1] if match else None


def artifact_roots(value):
    roots = set()
    if isinstance(value, dict):
        for key, child in value.items():
            if key == "path" and isinstance(child, str):
                root = store_root(child)
                if root and Path(root).exists():
                    roots.add(root)
            elif key != "drv_path":
                roots.update(artifact_roots(child))
    elif isinstance(value, list):
        for child in value:
            roots.update(artifact_roots(child))
    return roots


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--cache", default=os.environ.get("CACHIX_CACHE"),
                        help="Explicitly selected Cachix cache (or CACHIX_CACHE environment variable)")
    parser.add_argument("--list-only", action="store_true")
    args = parser.parse_args()
    if not args.cache:
        parser.error("Supply --cache or CACHIX_CACHE; this template has no default upload destination")
    repository = Path(__file__).resolve().parents[2]
    os.chdir(repository)
    profile = repository / ".build/cachix-seed-env"
    subprocess.run(["nix", "develop", "--profile", str(profile), "--command", "true"], check=True)
    flake = "f = builtins.getFlake (toString ./.)"
    metadata = command(
        "nix", "build", "--no-link", "--print-out-paths", "--impure", "--expr",
        f"let {flake}; in f.inputs.hull.lib.${{builtins.currentSystem}}.runtime.contestMetadataFile "
        "f.hullContests.${builtins.currentSystem}.default",
    )
    roots = artifact_roots(json.loads(Path(metadata).read_text())) | {metadata, str(profile.resolve())}
    for name in ("result-ci", "result-contest", "result-hydro", "result-statements"):
        path = repository / name
        if path.exists():
            root = store_root(path.resolve())
            if root:
                roots.add(root)
    # Cachix uploads these paths and their closures, not the user's entire store.
    paths = sorted(roots)
    print(f"Selected {len(paths)} project/toolchain roots for {args.cache}", flush=True)
    (repository / ".build/cachix-seed-paths.txt").write_text("\n".join(paths) + "\n")
    if args.list_only:
        return
    cachix = command(
        "nix", "build", "--no-link", "--print-out-paths", "--impure", "--expr",
        f"let {flake}; in f.inputs.nixpkgs.legacyPackages.${{builtins.currentSystem}}.cachix",
    )
    environment = os.environ.copy()
    if not environment.get("CACHIX_AUTH_TOKEN"):
        environment["CACHIX_AUTH_TOKEN"] = getpass.getpass("Cachix token (hidden, not saved): ")
    if not environment["CACHIX_AUTH_TOKEN"]:
        raise ValueError("No Cachix token supplied")
    subprocess.run([str(Path(cachix) / "bin/cachix"), "push", args.cache],
                   input="\n".join(paths) + "\n", text=True, env=environment, check=True)


if __name__ == "__main__":
    main()
