import hashlib
import json
from pathlib import Path
import tempfile
import unittest
from unittest.mock import patch

from plan import plan
from release_artifact import eligible, resolve, verify_manifest


class SelectionTests(unittest.TestCase):
    slugs = ["example-sum", "other-problem"]

    def test_statement_and_illustration_do_not_judge(self):
        result = plan([
            "problems/other-problem/document/statement/zh/description.typ",
            "problems/example-sum/document/statement/illustrations/example.png",
            "documents/statement-common.typ",
        ], self.slugs)
        self.assertEqual((result["full"], result["problems"], result["statements"]),
                         (False, [], True))

    def test_sample_and_solution_changes_select_only_the_problem(self):
        for path in ("data/samples/01.in", "document/statement/samples.json", "solution/std.20.cpp"):
            with self.subTest(path=path):
                result = plan([f"problems/other-problem/{path}"], self.slugs)
                self.assertEqual((result["full"], result["problems"]), (False, ["other-problem"]))

    def test_shared_unknown_or_removed_inputs_require_full_verification(self):
        for path in ("nix/problem.nix", "authoring-include/normalized_text.23.hpp",
                     "flake.lock", "contest.nix", ".github/workflows/check.yml",
                     "problems/removed/solution.cpp", "new-build-input.py"):
            with self.subTest(path=path):
                self.assertTrue(plan([path], self.slugs)["full"])

    def test_rename_old_and_new_paths_are_both_checked(self):
        result = plan(["problems/other-problem/solution/std.20.cpp",
                       "problems/example-sum/solution/std.20.cpp"], self.slugs)
        self.assertEqual(result["problems"], sorted(self.slugs))

    def test_documentation_only(self):
        result = plan(["README.md", "CLAUDE.md", "documents/ci.md"], self.slugs)
        self.assertEqual((result["full"], result["problems"], result["statements"]),
                         (False, [], False))


class ArtifactTests(unittest.TestCase):
    sha = "a" * 40

    def run_record(self, **overrides):
        run = dict(workflow_id=3, head_branch="main", event="push", head_sha=self.sha,
                   display_title=f"Verify {self.sha}", id=7, run_attempt=1,
                   status="completed", conclusion="success", html_url="https://example/run/7",
                   created_at="9999-01-01T00:00:00Z")
        return run | overrides

    def test_only_matching_main_or_explicit_rebuild_is_eligible(self):
        self.assertTrue(eligible(self.run_record(), self.sha, "main", 3))
        for overrides in (dict(event="pull_request"), dict(head_branch="feature"),
                          dict(workflow_id=4), dict(head_sha="b" * 40)):
            self.assertFalse(eligible(self.run_record(**overrides), self.sha, "main", 3))
        rebuilt = self.run_record(event="workflow_dispatch", head_sha="b" * 40)
        self.assertTrue(eligible(rebuilt, self.sha, "main", 3))
        self.assertFalse(eligible(rebuilt | {"display_title": "Verify another commit"},
                                  self.sha, "main", 3))

    @patch("release_artifact.time.sleep")
    @patch("release_artifact.api")
    @patch("release_artifact.find_artifact")
    def test_running_main_build_is_waited_for_without_dispatch(self, find, api, sleep):
        find.side_effect = [None, (7, "packages")]
        api.side_effect = [{"id": 3}, {"workflow_runs": [self.run_record(status="in_progress")]}]
        self.assertEqual(resolve("owner/repo", self.sha, "main", 60, 0), (7, "packages"))
        self.assertTrue(all(call.kwargs == {} and len(call.args) == 1 for call in api.call_args_list))

    @patch("release_artifact.time.sleep")
    @patch("release_artifact.api")
    @patch("release_artifact.find_artifact")
    def test_missing_artifact_dispatches_once_at_exact_sha(self, find, api, sleep):
        find.side_effect = [None, None, None, (8, "packages")]
        active = self.run_record(event="workflow_dispatch", status="in_progress")
        api.side_effect = [
            {"id": 3}, {"workflow_runs": []}, {"workflow_runs": []}, None,
            {"workflow_runs": [active]},
        ]
        self.assertEqual(resolve("owner/repo", self.sha, "main", 60, 0, 0), (8, "packages"))
        dispatches = [call for call in api.call_args_list if len(call.args) == 2]
        self.assertEqual(len(dispatches), 1)
        self.assertEqual(dispatches[0].args[1], {"ref": "main", "inputs": {"revision": self.sha}})

    @patch("release_artifact.api")
    @patch("release_artifact.find_artifact", return_value=None)
    def test_failed_verification_stops_release(self, find, api):
        api.side_effect = [{"id": 3}, {"workflow_runs": [self.run_record(conclusion="failure")]}]
        with self.assertRaisesRegex(RuntimeError, "did not succeed"):
            resolve("owner/repo", self.sha, "main", 60, 0)

    def test_manifest_checks_source_and_package_integrity(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            (root / "hydro").mkdir()
            files = ["statements.pdf", "contest-internal.tar.gz", "hydro/problem.zip"]
            for name in files:
                (root / name).write_bytes(b"example package")
            manifest = {"source_sha": self.sha, "files": {
                name: hashlib.sha256((root / name).read_bytes()).hexdigest() for name in files
            }}
            (root / "manifest.json").write_text(json.dumps(manifest))
            verify_manifest(root, self.sha)
            with self.assertRaisesRegex(ValueError, "different source"):
                verify_manifest(root, "b" * 40)
            (root / "hydro/problem.zip").write_bytes(b"corrupted")
            with self.assertRaisesRegex(ValueError, "checksum mismatch"):
                verify_manifest(root, self.sha)


if __name__ == "__main__":
    unittest.main()
