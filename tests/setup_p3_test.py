import importlib.util
import json
from pathlib import Path
import subprocess
import tempfile
import unittest


ROOT = Path(__file__).resolve().parent.parent
SCRIPT = ROOT / "skills/active/setup-p3/scripts/configure.py"
spec = importlib.util.spec_from_file_location("p3_setup", SCRIPT)
setup = importlib.util.module_from_spec(spec)
spec.loader.exec_module(setup)


def catalog(efforts=("low", "medium", "high", "max")):
    return {"providers": [{
        "providerInstanceId": "work", "canRunChildTask": True,
        "models": [{"id": model, "options": [{
            "id": "reasoningEffort", "options": [{"id": value} for value in efforts],
        }]} for model in ("code", "judge")],
    }]}


class SetupTests(unittest.TestCase):
    def test_medium_renders_high_roles_and_two_person_panel(self):
        text = setup.render_config(catalog(), "work/code", "work/judge", [], "medium")
        self.assertIn("# budget: medium (high)\n", text)
        self.assertIn("bug-fix: work/code (high)\n", text)
        self.assertIn("hardest tasks: work/judge (high)\n", text)
        self.assertIn("architect runners: work/code (high), work/judge (high)\n", text)

    def test_budget_never_selects_effort_above_ceiling(self):
        self.assertEqual(setup.model_entry(catalog(("medium", "max")), "work/code", "medium"), "work/code (medium)")

    def test_unknown_or_disabled_model_is_rejected(self):
        for selection in ("other/code", "work/missing", "malformed"):
            with self.subTest(selection=selection), self.assertRaises(ValueError):
                setup.model_entry(catalog(), selection, "medium")
        data = catalog()
        data["providers"][0]["canRunChildTask"] = False
        with self.assertRaises(ValueError):
            setup.model_entry(data, "work/code", "medium")

    def test_repeated_write_preserves_file_and_different_config_requires_replace(self):
        with tempfile.TemporaryDirectory() as directory:
            path = Path(directory) / "p3-models.md"
            self.assertTrue(setup.write_config(path, "first\n"))
            modified = path.stat().st_mtime_ns
            self.assertFalse(setup.write_config(path, "first\n"))
            self.assertEqual(path.stat().st_mtime_ns, modified)
            with self.assertRaises(ValueError):
                setup.write_config(path, "second\n")
            self.assertEqual(path.read_text(), "first\n")
            self.assertTrue(setup.write_config(path, "second\n", replace=True))
            self.assertEqual(path.read_text(), "second\n")

    def test_invalid_catalog_cli_does_not_write_configuration(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            (root / "catalog.json").write_text('{"providers": []}')
            result = subprocess.run([
                "python3", str(SCRIPT), "--catalog", str(root / "catalog.json"),
                "--coding", "work/code", "--judgment", "work/judge",
                "--output", str(root / "p3-models.md"),
            ], capture_output=True, text=True)
            self.assertNotEqual(result.returncode, 0)
            self.assertIn("Provider cannot run child tasks", result.stderr)
            self.assertFalse((root / "p3-models.md").exists())

    def test_check_rejects_existing_config_conflict_without_changing_it(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            (root / "catalog.json").write_text(json.dumps(catalog()))
            output = root / "p3-models.md"
            output.write_text("existing configuration\n")
            result = subprocess.run([
                "python3", str(SCRIPT), "--catalog", str(root / "catalog.json"),
                "--coding", "work/code", "--judgment", "work/judge",
                "--output", str(output), "--check",
            ], capture_output=True, text=True)
            self.assertNotEqual(result.returncode, 0)
            self.assertIn("Configuration differs", result.stderr)
            self.assertEqual(output.read_text(), "existing configuration\n")

    def test_log_helper_preserves_rows_and_escapes_formula_and_newline(self):
        helper = ROOT / "skills/active/show-me-your-work/scripts/log.sh"
        with tempfile.TemporaryDirectory() as directory:
            log = Path(directory) / "trail.tsv"
            for decision in ("first", "=formula\nsecond"):
                subprocess.run([str(helper), str(log), "check", decision, "reason", "evidence", "passed"], check=True)
            rows = log.read_text().splitlines()
            self.assertEqual(len(rows), 3)
            self.assertEqual(rows[1].split("\t")[2], "first")
            self.assertEqual(rows[2].split("\t")[2], "'=formula second")


if __name__ == "__main__":
    unittest.main()
