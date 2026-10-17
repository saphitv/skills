"""Check routing and change detection without accessing GitHub or agent accounts."""

import contextlib
import importlib.util
import io
import json
from pathlib import Path
import tempfile
import unittest


spec = importlib.util.spec_from_file_location(
    "check_upstreams", Path(__file__).resolve().parents[1] / "scripts/check-upstreams.py"
)
checker = importlib.util.module_from_spec(spec)
spec.loader.exec_module(checker)


class UpstreamTests(unittest.TestCase):
    def test_active_skill_without_mapping_is_rejected(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            skill = root / "skills/active/new-skill"
            skill.mkdir(parents=True)
            (skill / "SKILL.md").write_text("new skill")
            (root / "upstreams.json").write_text(json.dumps({"upstreams": {}, "skills": {}}))
            with self.assertRaisesRegex(ValueError, "new-skill"):
                checker.load_manifest(root)

    def test_inactive_mapping_is_rejected(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            (root / "upstreams.json").write_text(json.dumps({
                "upstreams": {}, "skills": {"archived-skill": {"upstream": "local", "adaptations": []}}
            }))
            with self.assertRaisesRegex(ValueError, "archived-skill"):
                checker.load_manifest(root)

    def test_changes_include_added_deleted_and_executable_files(self):
        before = {"deleted": ("old", "100644"), "script": ("same", "100644")}
        after = {"added": ("new", "100644"), "script": ("same", "100755")}
        self.assertEqual(checker.changes_between(before, after), [
            ("A", "added"), ("D", "deleted"), ("M", "script")
        ])

    def test_full_path_prefix_does_not_include_neighboring_skill(self):
        tree = {"skills/how/SKILL.md": "tracked", "skills/how-extra/SKILL.md": "unrelated"}
        self.assertEqual(checker.select_paths(tree, ["skills/how"]), {"skills/how/SKILL.md": "tracked"})

    def test_missing_baseline_path_is_an_error_and_deleted_head_is_a_change(self):
        with self.assertRaisesRegex(ValueError, "missing"):
            checker.select_paths({}, ["skills/how"])
        before = checker.select_paths({"skills/how/SKILL.md": "old"}, ["skills/how"])
        after = checker.select_paths({}, ["skills/how"], require_paths=False)
        self.assertEqual(checker.changes_between(before, after), [("D", "skills/how/SKILL.md")])

    def test_each_skill_uses_its_assigned_upstream_and_supporting_paths(self):
        class FakeGitHub:
            calls = []

            def head(self, repository, branch):
                self.calls.append((repository, branch))
                return "new"

            def tree(self, repository, commit):
                if repository == "author/p3":
                    return {"skills/how/SKILL.md": "same", "skills/how/references/prompt.md": commit}
                return {"pstack/skills/tdd/SKILL.md": "same", "pstack/skills/other/SKILL.md": commit}

        data = {
            "upstreams": {
                "p3-stack": {"repository": "author/p3", "branch": "main"},
                "pstack": {"repository": "author/pstack", "branch": "main"},
            },
            "skills": {
                "how": {"upstream": "p3-stack", "paths": ["skills/how"], "reviewed_commit": "old"},
                "tdd": {"upstream": "pstack", "paths": ["pstack/skills/tdd"], "reviewed_commit": "old"},
                "upload-file": {"upstream": "local"},
            },
        }
        github = FakeGitHub()
        with contextlib.redirect_stdout(io.StringIO()) as output:
            status = checker.check_upstreams(data, sorted(data["skills"]), github)
        self.assertEqual(status, 0)
        self.assertIn("REVIEW how", output.getvalue())
        self.assertIn("M skills/how/references/prompt.md", output.getvalue())
        self.assertIn("CURRENT tdd", output.getvalue())
        self.assertIn("LOCAL upload-file", output.getvalue())
        self.assertEqual(github.calls, [("author/p3", "main"), ("author/pstack", "main")])

    def test_api_failure_does_not_report_current_and_returns_failure(self):
        class BrokenGitHub:
            def head(self, repository, branch):
                raise checker.URLError("unavailable")

        data = {
            "upstreams": {"p3-stack": {"repository": "author/p3", "branch": "main"}},
            "skills": {"how": {"upstream": "p3-stack"}},
        }
        with contextlib.redirect_stdout(io.StringIO()) as output, contextlib.redirect_stderr(io.StringIO()) as errors:
            status = checker.check_upstreams(data, ["how"], BrokenGitHub())
        self.assertEqual(status, 1)
        self.assertNotIn("CURRENT", output.getvalue())
        self.assertIn("ERROR p3-stack", errors.getvalue())


if __name__ == "__main__":
    unittest.main()
