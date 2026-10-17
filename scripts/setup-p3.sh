#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
configure="$repo_root/skills/active/setup-p3/scripts/configure.py"
codex_skills="${CODEX_HOME:-$HOME/.codex}/skills"
agents_skills="$HOME/.agents/skills"

for argument in "$@"; do
  case "$argument" in
    --help|-h|--check) exec python3 "$configure" "$@" ;;
  esac
done

python3 "$configure" "$@" --check >/dev/null

while IFS= read -r skill; do
  destination="$agents_skills/$skill"
  target="$codex_skills/$skill"
  if [ -e "$destination" ] || [ -L "$destination" ]; then
    if [ -L "$destination" ] && [ "$(readlink "$destination")" = "$target" ]; then
      continue
    fi
    if [ -L "$destination" ] && [ -d "$destination" ] && [ -d "$target" ] &&
      [ "$(cd "$destination" && pwd -P)" = "$(cd "$target" && pwd -P)" ]; then
      continue
    fi
    echo "Existing discovery entry needs review: $destination" >&2
    exit 1
  fi
done < "$repo_root/profiles/pstack.txt"

"$repo_root/scripts/install.sh"
python3 "$configure" "$@"
mkdir -p "$agents_skills"
while IFS= read -r skill; do
  destination="$agents_skills/$skill"
  if [ ! -e "$destination" ] && [ ! -L "$destination" ]; then
    ln -s "$codex_skills/$skill" "$destination"
  fi
done < "$repo_root/profiles/pstack.txt"
echo "P3 skills, discovery links, and model configuration are ready."
