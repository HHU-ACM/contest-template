"""Reuse a successful main build for a tag; rebuild once if its artifact is missing."""
import argparse
from datetime import datetime, timezone
import hashlib
import json
from pathlib import Path, PurePosixPath
import re
import subprocess
import time
from urllib.parse import urlencode


def gh(*args, payload=None):
    return subprocess.check_output(
        ["gh", *args], text=True,
        input=None if payload is None else json.dumps(payload),
    )


def api(path, payload=None):
    args = ["api", path]
    if payload is not None:
        args += ["--method", "POST", "--input", "-"]
    return json.loads(gh(*args, payload=payload) or "null")


def eligible(run, sha, branch, workflow_id):
    if run["workflow_id"] != workflow_id or run["head_branch"] != branch:
        return False
    if run["event"] == "push":
        return run["head_sha"] == sha
    return (run["event"] == "workflow_dispatch"
            and run["display_title"] == f"Verify {sha}")


def verify_manifest(directory, sha):
    root = Path(directory)
    manifest = json.loads((root / "manifest.json").read_text())
    if manifest["source_sha"] != sha:
        raise ValueError("Artifact belongs to a different source commit")
    files = manifest["files"]
    if ("statements.pdf" not in files or "contest-internal.tar.gz" not in files
            or not any(name.startswith("hydro/") and name.endswith(".zip") for name in files)):
        raise ValueError("Artifact is missing release packages")
    for name, digest in files.items():
        relative = PurePosixPath(name)
        if relative.is_absolute() or ".." in relative.parts:
            raise ValueError("Invalid artifact file path")
        path = root / relative
        if path.is_symlink() or hashlib.sha256(path.read_bytes()).hexdigest() != digest:
            raise ValueError(f"Artifact checksum mismatch: {name}")
    actual = {str(path.relative_to(root)) for path in root.rglob("*") if path.is_file()}
    if actual != set(files) | {"manifest.json"}:
        raise ValueError("Artifact contains unlisted files")


def find_artifact(repo, sha, branch, workflow_id):
    name = f"contest-packages-{sha}"
    query = urlencode({"name": name, "per_page": 100})
    artifacts = api(f"repos/{repo}/actions/artifacts?{query}")["artifacts"]
    for artifact in sorted(artifacts, key=lambda item: item["id"], reverse=True):
        if artifact["name"] != name or artifact["expired"]:
            continue
        run = api(f"repos/{repo}/actions/runs/{artifact['workflow_run']['id']}")
        if eligible(run, sha, branch, workflow_id) and run["conclusion"] == "success":
            return run["id"], name
    return None


def resolve(repo, sha, branch, timeout, interval, discovery_grace=60):
    workflow_id = api(f"repos/{repo}/actions/workflows/check.yml")["id"]
    deadline = time.monotonic() + timeout
    dispatched_at = None
    missing_since = None
    while time.monotonic() < deadline:
        artifact = find_artifact(repo, sha, branch, workflow_id)
        if artifact:
            return artifact
        # Recent main runs cover normal tag publishing. Old releases without a
        # retained artifact get an explicitly named dispatch at this exact SHA.
        query = urlencode({"branch": branch, "per_page": 100})
        runs = api(f"repos/{repo}/actions/workflows/check.yml/runs?{query}")["workflow_runs"]
        candidates = [run for run in runs if eligible(run, sha, branch, workflow_id)]
        if dispatched_at is not None:
            candidates = [run for run in candidates if run["created_at"] >= dispatched_at]
        latest = max(candidates, key=lambda run: (run["id"], run["run_attempt"]), default=None)
        if latest and latest["status"] != "completed":
            print(f"Waiting for full verification: {latest['html_url']}", flush=True)
        elif latest and latest["conclusion"] != "success":
            raise RuntimeError(f"Full verification did not succeed: {latest['html_url']}")
        elif latest is None and dispatched_at is None and (
                missing_since is None or time.monotonic() - missing_since < discovery_grace):
            # A tag can arrive before GitHub has registered the main push run.
            if missing_since is None:
                missing_since = time.monotonic()
            print("Waiting for the main workflow to appear", flush=True)
        elif dispatched_at is None:
            dispatched_at = datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")
            api(f"repos/{repo}/actions/workflows/check.yml/dispatches", {
                "ref": branch, "inputs": {"revision": sha},
            })
            print(f"No retained artifact; requested one full build of {sha}", flush=True)
        elif latest:
            raise RuntimeError(f"Rebuild succeeded without the required artifact: {latest['html_url']}")
        time.sleep(interval)
    raise TimeoutError("Timed out waiting for verified release packages")


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--repo", required=True)
    parser.add_argument("--tag", required=True)
    parser.add_argument("--directory", default="dist")
    parser.add_argument("--timeout", type=int, default=3600)
    parser.add_argument("--interval", type=int, default=20)
    args = parser.parse_args()
    if not re.fullmatch(r"v[A-Za-z0-9._-]+", args.tag):
        parser.error("Expected a v-prefixed release tag")
    tag = api(f"repos/{args.repo}/git/ref/tags/{args.tag}")
    obj = tag["object"]
    while obj["type"] == "tag":
        obj = api(f"repos/{args.repo}/git/tags/{obj['sha']}")["object"]
    if obj["type"] != "commit":
        raise ValueError("Release tag does not point to a commit")
    sha = obj["sha"]
    branch = api(f"repos/{args.repo}")["default_branch"]
    comparison = api(f"repos/{args.repo}/compare/{sha}...{branch}")
    if comparison["status"] not in ("identical", "ahead"):
        raise ValueError("Release commit must be on the default branch")
    run_id, name = resolve(args.repo, sha, branch, args.timeout, args.interval)
    gh("run", "download", str(run_id), "--repo", args.repo,
       "--name", name, "--dir", args.directory)
    verify_manifest(args.directory, sha)
    # Recheck the tag after waiting, before handing packages to publication.
    if api(f"repos/{args.repo}/commits/{args.tag}")["sha"] != sha:
        raise ValueError("Release tag moved while waiting for artifacts")
    print(f"Verified packages for {sha}, reused from run {run_id}")


if __name__ == "__main__":
    main()
