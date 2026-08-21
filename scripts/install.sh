#!/usr/bin/env bash
set -euo pipefail

usage() {
  echo "Usage: ./scripts/install.sh [--lock] [skill ...]" >&2
  exit 64
}

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
codex_home="${CODEX_HOME:-$HOME/.codex}"
claude_config_dir="${CLAUDE_CONFIG_DIR:-$HOME/.claude}"
targets=("$codex_home/skills" "$claude_config_dir/skills")
mode=install

case "${1-}" in
  --lock) mode=lock; shift ;;
  "") ;;
  -h|--help) usage ;;
  *) ;;
esac

if [ "${1-}" = "--lock" ] || [ "${1-}" = "-h" ] || [ "${1-}" = "--help" ]; then
  usage
fi

selected=("$@")
for skill in "${selected[@]-}"; do
  [ -n "$skill" ] || continue
  [ -f "$repo_root/skills/$skill/SKILL.md" ] || {
    echo "Unknown skill: $skill" >&2
    exit 66
  }
done

current_commit="$(git -C "$repo_root" rev-parse HEAD)"
installed_at="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
state="$(mktemp)"
trap 'rm -f "$state" "$repo_root/lock.json.tmp"' EXIT
cp "$repo_root/lock.json" "$state"

write_lock() {
  local skill=$1 destination=$2 sha=$3
  jq -c --arg skill "$skill" --arg destination "$destination" --arg sha "$sha" \
    --arg installed_at "$installed_at" \
    '.installs |= map(select(.skill != $skill and .destination != $destination)) + [{
      skill: $skill,
      destination: $destination,
      source_commit: $sha,
      installed_at: $installed_at,
      files: []
    }]' "$repo_root/lock.json" > "$repo_root/lock.json.tmp"
  mv "$repo_root/lock.json.tmp" "$state"
}

record_files() {
  local skill=$1 destination=$2
  local relative file hash entries entry
  entries="[]"
  while IFS= read -r relative; do
    file="$destination/$relative"
    hash=$(shasum -a 256 "$file" | awk '{print $1}')
    entry=$(jq -cn --arg path "$relative" --arg hash "$hash" '{path: $path, sha256: $hash}')
    entries=$(jq -c --argjson entries "$entries" --argjson entry "$entry" '$entries + [$entry]')
  done < <(cd "$destination" && find . -type f | sed 's#^\./##' | sort)
  jq -c --arg skill "$skill" --arg destination "$destination" --argjson files "$entries" \
    '(.installs[] | select(.skill == $skill and .destination == $destination)).files = $files' \
    "$state" > "$repo_root/lock.json.tmp"
  mv "$repo_root/lock.json.tmp" "$state"
}

commit_lock() {
  jq -S . "$state" > "$repo_root/lock.json"
}

install_skill() {
  local skill=$1 target=$2 destination="$3/$1"
  mkdir -p "$3"

  if [ -e "$destination" ] && [ ! -d "$destination" ]; then
    echo "Refusing to replace non-directory: $destination" >&2
    exit 73
  fi

  if [ -d "$destination" ]; then
    local owned
    owned=$(jq -r --arg skill "$skill" --arg destination "$destination" \
      '[.installs[] | select(.skill == $skill and .destination == $destination) | .files[].path] | .[]' \
      "$state" || true)
    if [ -n "$owned" ]; then
      rm -rf "$destination"
    else
      echo "Refusing unmanaged directory without lock data: $destination" >&2
      exit 73
    fi
  fi

  cp -R "$repo_root/skills/$skill" "$destination"
  write_lock "$skill" "$destination" "$current_commit"
  record_files "$skill" "$destination"
}

for skill in skills/*; do
  name=${skill##*/}
  if [ ! -f "$skill/SKILL.md" ]; then
    continue
  fi
  if [ "${#selected[@]}" -gt 0 ]; then
    matched=false
    for wanted in "${selected[@]}"; do
      if [ "$wanted" = "$name" ]; then
        matched=true
        break
      fi
    done
    $matched || continue
  fi

  echo "Installing $name"
  for target in "${targets[@]}"; do
    install_skill "$name" "$target" "$target"
  done
done

commit_lock

if [ "$mode" = lock ]; then
  echo "Locked $current_commit"
else
  echo "Installed skills from $current_commit"
fi
