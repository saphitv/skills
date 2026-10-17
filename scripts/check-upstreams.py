#!/usr/bin/env python3
"""Report upstream changes without comparing or replacing adapted local copies."""

import argparse
import json
import os
from pathlib import Path, PurePosixPath
import re
import sys
from urllib.error import URLError
from urllib.parse import quote
from urllib.request import Request, urlopen


REPO_ROOT = Path(__file__).resolve().parent.parent


def load_manifest(root):
    data = json.loads((root / "upstreams.json").read_text())
    upstreams, skills = data["upstreams"], data["skills"]
    active = {p.parent.name for p in (root / "skills/active").glob("*/SKILL.md")}
    missing, extra = active - skills.keys(), skills.keys() - active
    if missing or extra:
        raise ValueError(
            f"upstream coverage differs from active skills; missing: {sorted(missing)}; "
            f"inactive or unknown: {sorted(extra)}"
        )
    for name, source in upstreams.items():
        if not re.fullmatch(r"[\w.-]+/[\w.-]+", source["repository"]):
            raise ValueError(f"{name}: expected a GitHub owner/repository")
        if not isinstance(source["branch"], str) or not source["branch"]:
            raise ValueError(f"{name}: branch must be a nonempty string")
    for name, skill in skills.items():
        if not isinstance(skill["adaptations"], list) or not all(
            isinstance(note, str) and note for note in skill["adaptations"]
        ):
            raise ValueError(f"{name}: adaptations must be a list of nonempty strings")
        if skill["upstream"] == "local":
            if "paths" in skill or "reviewed_commit" in skill:
                raise ValueError(f"{name}: locally maintained skills cannot have upstream paths or commits")
            continue
        if skill["upstream"] not in upstreams:
            raise ValueError(f"{name}: unknown upstream {skill['upstream']}")
        if not re.fullmatch(r"[0-9a-f]{40}", skill["reviewed_commit"]):
            raise ValueError(f"{name}: reviewed_commit must be a full commit SHA")
        paths = skill["paths"]
        if not isinstance(paths, list) or not paths or not all(isinstance(p, str) for p in paths):
            raise ValueError(f"{name}: paths must be a nonempty list of repository paths")
        if len(paths) != len(set(paths)):
            raise ValueError(f"{name}: duplicate upstream paths")
        for path in paths:
            if not path or PurePosixPath(path).is_absolute() or ".." in PurePosixPath(path).parts:
                raise ValueError(f"{name}: invalid upstream path {path!r}")
            if str(PurePosixPath(path)) != path or path == ".":
                raise ValueError(f"{name}: expected a normalized repository path, got {path!r}")
    return data


def select_paths(tree, paths, require_paths=True):
    selected = {}
    for path in paths:
        matches = {p: value for p, value in tree.items() if p == path or p.startswith(path + "/")}
        if require_paths and not matches:
            raise ValueError(f"tracked path missing from reviewed revision: {path}")
        selected.update(matches)
    return selected


def changes_between(before, after):
    return [
        ("A" if path not in before else "D" if path not in after else "M", path)
        for path in sorted(before.keys() | after.keys())
        if before.get(path) != after.get(path)
    ]


class GitHub:
    def __init__(self):
        self.cache = {}

    def get(self, path):
        if path not in self.cache:
            headers = {"Accept": "application/vnd.github+json", "User-Agent": "agent-skills-upstream-check"}
            token = os.environ.get("GH_TOKEN") or os.environ.get("GITHUB_TOKEN")
            if token:
                headers["Authorization"] = f"Bearer {token}"
            with urlopen(Request("https://api.github.com/" + path, headers=headers), timeout=30) as response:
                self.cache[path] = json.load(response)
        return self.cache[path]

    def head(self, repository, branch):
        return self.get(f"repos/{repository}/commits/{quote(branch, safe='')}")["sha"]

    def tree(self, repository, commit):
        data = self.get(f"repos/{repository}/git/trees/{commit}?recursive=1")
        if data.get("truncated"):
            raise ValueError(f"{repository}: GitHub truncated the tree; inspect the tracked paths manually")
        return {entry["path"]: (entry["sha"], entry["mode"]) for entry in data["tree"] if entry["type"] != "tree"}


def check_upstreams(data, names, github):
    failed = False
    for upstream, source in data["upstreams"].items():
        selected = [name for name in names if data["skills"][name]["upstream"] == upstream]
        if not selected:
            continue
        repository = source["repository"]
        try:
            head = github.head(repository, source["branch"])
            latest = github.tree(repository, head)
        except (URLError, ValueError, KeyError, TypeError) as error:
            print(f"ERROR {upstream}: {error}", file=sys.stderr)
            failed = True
            continue
        print(f"{upstream}: https://github.com/{repository} @ {head}")
        for name in selected:
            skill = data["skills"][name]
            base = skill["reviewed_commit"]
            try:
                before = select_paths(github.tree(repository, base), skill["paths"])
                after = select_paths(latest, skill["paths"], require_paths=False)
                changes = changes_between(before, after)
            except (URLError, ValueError, KeyError, TypeError) as error:
                print(f"  ERROR {name}: {error}", file=sys.stderr)
                failed = True
                continue
            if changes:
                print(f"  REVIEW {name}: {len(changes)} upstream file(s) changed")
                print(f"    https://github.com/{repository}/compare/{base}...{head}")
                for status, path in changes:
                    print(f"    {status} {path}")
            else:
                print(f"  CURRENT {name}: tracked upstream files unchanged")
    for name in names:
        if data["skills"][name]["upstream"] == "local":
            print(f"LOCAL {name}: maintained in this repository")
    print("Read-only report. REVIEW means upstream changes need inspection; local adaptations are not compared.")
    return 1 if failed else 0


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--validate", action="store_true", help="validate active-skill coverage without network access")
    parser.add_argument("skills", nargs="*", help="check selected active skills; default: all active skills")
    args = parser.parse_args()
    try:
        data = load_manifest(REPO_ROOT)
        names = sorted(set(args.skills) if args.skills else data["skills"])
        unknown = set(names) - data["skills"].keys()
        if unknown:
            raise ValueError(f"unknown active skills: {', '.join(sorted(unknown))}")
        if args.validate:
            print(f"Valid upstream map: {len(data['skills'])} active skills, each with one update source.")
            return 0
        return check_upstreams(data, names, GitHub())
    except (OSError, ValueError, KeyError, TypeError) as error:
        print(f"ERROR: {error}", file=sys.stderr)
        return 1


if __name__ == "__main__":
    sys.exit(main())
