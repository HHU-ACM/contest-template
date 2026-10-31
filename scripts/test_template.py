"""Regression tests for authoring operations that change the workspace."""
import importlib.util
import json
from pathlib import Path
import shutil
import tempfile
import unittest

from check_samples import check, check_problem

ROOT = Path(__file__).resolve().parents[1]
spec = importlib.util.spec_from_file_location("new_problem", ROOT / "scripts/new-problem.py")
new_problem = importlib.util.module_from_spec(spec)
spec.loader.exec_module(new_problem)
preview_spec = importlib.util.spec_from_file_location("prepare_statements", ROOT / "nix/prepare-statements.py")
preview = importlib.util.module_from_spec(preview_spec)
preview_spec.loader.exec_module(preview)


class TemplateTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name)
        shutil.copytree(ROOT / "templates", self.root / "templates")
        self.contest = self.root / "contest.nix"
        self.contest.write_text('{\n  problems = [\n  ];\n}\n')

    def test_create_without_example_and_escape_nix_interpolation(self):
        title = '求和 "引号" ${builtins.abort "unexpected"} \\ 路径'
        destination = new_problem.create(self.root, "array-sum", title)
        config = (destination / "problem.nix").read_text()
        self.assertIn('name = "arraySum";', config)
        self.assertIn(r'\${builtins.abort', config)
        self.assertIn(r'\"引号\"', config)
        self.assertEqual(preview.nix_string_field(config, "title"), title)
        self.assertEqual(self.contest.read_text().count('./problems/array-sum/problem.nix'), 1)
        check(self.root)

    def test_refuse_existing_directory_without_modifying_anything(self):
        destination = new_problem.create(self.root, "array-sum", "求和")
        sentinel = destination / "keep.txt"
        sentinel.write_text("user work")
        original = self.contest.read_bytes()
        with self.assertRaisesRegex(ValueError, "拒绝覆盖"):
            new_problem.create(self.root, "array-sum", "覆盖")
        self.assertEqual(sentinel.read_text(), "user work")
        self.assertEqual(original, self.contest.read_bytes())

    def test_reject_path_escape_bad_title_and_identifier_collision(self):
        for slug, title in [("../escape", "题"), ("UpperCase", "题"), ("x", "\n注入")]:
            with self.subTest(slug=slug), self.assertRaises(ValueError):
                new_problem.create(self.root, slug, title)
        new_problem.create(self.root, "array-1", "求和")
        original = self.contest.read_bytes()
        with self.assertRaisesRegex(ValueError, "冲突"):
            new_problem.create(self.root, "array1", "求和")
        self.assertEqual(original, self.contest.read_bytes())
        self.assertFalse((self.root / "problems/array1").exists())

    def test_unsupported_contest_expression_does_not_create_problem(self):
        self.contest.write_text('{ problems = import ./problem-list.nix; }')
        with self.assertRaisesRegex(ValueError, "字面量"):
            new_problem.create(self.root, "new-sum", "求和")
        self.assertFalse((self.root / "problems/new-sum").exists())

    def test_preview_refuses_dynamic_title(self):
        with self.assertRaisesRegex(ValueError, "interpolation"):
            preview.nix_string_field('title = "${dynamic}";', "title")

    def test_compact_empty_contest_list(self):
        self.contest.write_text('{ problems = []; }')
        new_problem.create(self.root, "new-sum", "求和")
        check(self.root)

    def test_sample_mismatch_and_missing_output_are_detected(self):
        destination = new_problem.create(self.root, "new-sum", "求和")
        samples = destination / "document/statement/samples.json"
        data = json.loads(samples.read_text())
        data[0]["output"] = "wrong\n"
        samples.write_text(json.dumps(data))
        with self.assertRaisesRegex(ValueError, "不一致"):
            check_problem(destination)
        (destination / "data/samples/01.out").unlink()
        with self.assertRaisesRegex(ValueError, "一一配对"):
            check_problem(destination)


if __name__ == "__main__":
    unittest.main()
