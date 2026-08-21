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
  --lock)
    mode=lock
    shift
    ;;
  -h|--help)
    usage
    ;;
esac

if [ "${1-}" = "--lock" ]; then
  usage
fi

selected=("$@")
if [ "${#selected[@]}" -gt 0 ]; then
  for skill in "${selected[@]}"; do
    if [ ! -f "$repo_root/skills/$skill/SKILL.md" ]; then
      echo "Unknown skill: $skill" >&2
      exit 66
    fi
  done
fi

current_commit="$(git -C "$repo_root" rev-parse HEAD)"
installed_at="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
state="$(mktemp)"
file_manifest="$(mktemp)"
trap 'rm -f "$state" "$file_manifest"' EXIT
jq -S . "$repo_root/lock.json" > "$state"

record_files() {
  local skill=$1 destination=$2 relative file hash
  printf '[]\n' > "$file_manifest"

  while IFS= read -r relative; do
    file="$destination/$relative"
    hash=$(shasum -a 256 "$file" | awk '{print $1}')
    jq -c --arg path "$relative" --arg sha256 "$hash" \
      '. + [{path: $path, sha256: $sha256}]' "$file_manifest" > "$file_manifest.next"
    mv "$file_manifest.next" "$file_manifest"
  done < <(cd "$destination" && find . -type f | sed 's#^\./##' | sort)

  jq -c --arg skill "$skill" --arg destination "$destination" \
    --slurpfile files "$file_manifest" '
      (.installs[] | select(.skill == $skill and .destination == $destination)).files = $files[0]
    ' "$state" > "$state.next"
  mv "$state.next" "$state"
}

write_record() {
  local skill=$1 destination=$2
  jq -c --arg skill "$skill" --arg destination "$destination" \
    --arg source_commit "$current_commit" --arg installed_at "$installed_at" '
      .installs |= map(select(.skill != $skill or .destination != $destination))
        + [{
            skill: $skill,
            destination: $destination,
            source_commit: $source_commit,
            installed_at: $installed_at,
            files: []
          }]
    ' "$state" > "$state.next"
  mv "$state.next" "$state"
}

install_skill() {
  local skill=$1 target=$2 destination="$target/$1"
  mkdir -p "$target"

  if [ -e "$destination" ] && [ ! -d "$destination" ]; then
    echo "Refusing to replace non-directory: $destination" >&2
    exit 73
  fi

  if [ -d "$destination" ]; then
    jq -r --arg skill "$skill" --arg destination "$destination" '
      [.installs[]
        | select(.skill == $skill and .destination == $destination)
        | .files[].path] | .[]
    ' "$state" >/dev/null
    rm -rf "$destination"
  fi

  cp -R "$repo_root/skills/$skill" "$destination"
  write_record "$skill" "$destination"
  record_files "$skill" "$destination"
}

for source in skills/*; do
  name=${source##*/}

  if [ ! -f "$source/SKILL.md" ]; then
    continue
  fi

  selected_count=${#selected[@]}
  if [ "$selected_count" -gt 0 ]; then
    matched=false
    for wanted in "${selected[@]}"; do
      if [ "$wanted" = "$name" ]; then
        matched=true
        break
      fi
    done
    if [ "$matched" = false ]; then
      continue
    fi
  fi

  echo "Installing $name"
  for target in "${targets[@]}"; do
    install_skill "$name" "$target"
  done
done

jq -S . "$state" > "$repo_root/lock.json.tmp"
mv "$repo_root/lock.json.tmp" "$repo_root/lock.json"

if [ "$mode" = lock ]; then
  echo "Locked $current_commit"
else
  echo "Installed skills from $current_commit"
fi
