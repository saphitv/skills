#!/usr/bin/env python3
"""Write P3 roles from an explicitly selected host model catalog."""

import argparse
import json
import os
from pathlib import Path
import tempfile


BUDGETS = {"small": "medium", "medium": "high", "large": "xhigh", "unlimited": "max"}
EFFORTS = ["low", "medium", "high", "xhigh", "max", "ultra"]
CODE_ROLES = [
    "feature, refactoring", "bug-fix", "perf-issue", "hillclimb",
    "how explorer", "why investigators", "swarm workers",
]
JUDGMENT_ROLES = [
    "judgment and prose", "hardest tasks", "how explainer", "why synthesizer",
    "reflect tooling", "reflect judgment, divergent, synthesizer",
]
PANEL_ROLES = ["arena runners", "architect runners", "interrogate reviewers"]


def model_entry(catalog, selection, budget):
    provider_id, separator, model_id = selection.partition("/")
    if not separator or not model_id:
        raise ValueError(f"Expected provider/model, got {selection!r}")
    providers = [p for p in catalog["providers"] if p["providerInstanceId"] == provider_id]
    if len(providers) != 1 or not providers[0].get("canRunChildTask", False):
        raise ValueError(f"Provider cannot run child tasks: {provider_id}")
    models = [m for m in providers[0]["models"] if m["id"] == model_id]
    if len(models) != 1:
        raise ValueError(f"Model is absent from this host's catalog: {selection}")
    descriptors = [d for d in models[0].get("options", []) if d["id"] in ("reasoningEffort", "effort")]
    if not descriptors:
        return selection
    descriptor = descriptors[0]
    supported = set(descriptor["values"]) if "values" in descriptor else {o["id"] for o in descriptor["options"]}
    ceiling = len(EFFORTS) - 1 if budget == "unlimited" else EFFORTS.index(BUDGETS[budget])
    eligible = [effort for effort in EFFORTS[:ceiling + 1] if effort in supported]
    if not eligible:
        raise ValueError(f"No supported reasoning effort within {budget} budget: {selection}")
    return f"{selection} ({eligible[-1]})"


def render_config(catalog, coding, judgment, reviewers, budget, ui_design=None):
    code = model_entry(catalog, coding, budget)
    judge = model_entry(catalog, judgment, budget)
    review = [model_entry(catalog, value, budget) for value in reviewers]
    designer = model_entry(catalog, ui_design or (reviewers[0] if reviewers else judgment), budget)
    panel = list(dict.fromkeys([code] + (review or [judge])))
    if len(panel) == 1:
        panel *= 2
    pool = list(dict.fromkeys([judge] + review))
    lines = [
        "# P3 model configuration. Project p3-models.md overrides the global file.",
        "# Resolve provider/model and effort against this host's live catalog before delegation.",
        f"# budget: {budget} ({BUDGETS[budget]})",
    ]
    lines += [f"{role}: {code}" for role in CODE_ROLES]
    lines += [f"{role}: {judge}" for role in JUDGMENT_ROLES]
    lines += [f"UI prototyping, visual design: {designer}"]
    lines += [f"{role}: {', '.join(panel)}" for role in PANEL_ROLES]
    lines += [f"arena cross-judge pool: {', '.join(pool)}"]
    return "\n".join(lines) + "\n"


def needs_write(path, text, replace=False):
    if path.exists():
        if path.read_text() == text:
            return False
        if not replace:
            raise ValueError(f"Configuration differs at {path}; review it and use --replace to update it")
    return True


def write_config(path, text, replace=False):
    if not needs_write(path, text, replace):
        return False
    path.parent.mkdir(parents=True, exist_ok=True)
    descriptor, temporary = tempfile.mkstemp(prefix=f".{path.name}.", dir=path.parent)
    try:
        with os.fdopen(descriptor, "w") as output:
            output.write(text)
        os.replace(temporary, path)
    finally:
        Path(temporary).unlink(missing_ok=True)
    return True


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--catalog", required=True, type=Path, help="orchestrator_capabilities JSON from the target host")
    parser.add_argument("--coding", required=True, help="providerInstanceId/model for code and exploration")
    parser.add_argument("--judgment", required=True, help="providerInstanceId/model for judgment and synthesis")
    parser.add_argument("--ui-design", help="providerInstanceId/model for UI prototypes; defaults to the first reviewer or judgment")
    parser.add_argument("--reviewer", action="append", default=[], help="panel model; repeat for more reviewers")
    parser.add_argument("--budget", choices=BUDGETS, default="medium")
    parser.add_argument("--output", type=Path, default=Path.home()/".agents/p3-models.md")
    parser.add_argument("--check", action="store_true", help="validate and print without writing")
    parser.add_argument("--replace", action="store_true", help="replace a differing existing model configuration")
    args = parser.parse_args()
    try:
        catalog = json.loads(args.catalog.read_text())
        text = render_config(catalog, args.coding, args.judgment, args.reviewer, args.budget, args.ui_design)
        if args.check:
            needs_write(args.output.expanduser(), text, args.replace)
            print(text, end="")
            return
        changed = write_config(args.output.expanduser(), text, args.replace)
        print(f"{'Wrote' if changed else 'Already current:'} {args.output.expanduser()}")
    except (OSError, ValueError, KeyError, TypeError) as error:
        parser.exit(1, f"P3 setup failed: {error}\n")


if __name__ == "__main__":
    main()
