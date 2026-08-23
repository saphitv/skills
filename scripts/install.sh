#!/usr/bin/env bash
set -euo pipefail

usage() {
  local status=${1:-64}
  cat >&2 <<'EOF'
Usage:
  ./scripts/install.sh [install] [skill ...]
  ./scripts/install.sh status [skill ...]
  ./scripts/install.sh prune [--yes]

Commands:
  install  Replace active skills in both agent accounts (default).
  status   Report missing, outdated, stale, and unmanaged skills.
  prune    Remove installed skills that this installer manages but that are
           no longer active. Prompts unless --yes is supplied.
EOF
  exit "$status"
}

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
skills_root="$repo_root/skills"
active_dir="$skills_root/active"
disabled_dir="$skills_root/disabled"
archived_dir="$skills_root/archived"
codex_home="${CODEX_HOME:-$HOME/.codex}"
claude_config_dir="${CLAUDE_CONFIG_DIR:-$HOME/.claude}"
targets=("$codex_home/skills" "$claude_config_dir/skills")
target_labels=(Codex Claude)
lock_file="$repo_root/.agent-skills.lock.json"
action=install
assume_yes=false

case "${1-}" in
  install)
    shift
    ;;
  status|--status|--check)
    action=status
    shift
    ;;
  prune|--prune)
    action=prune
    shift
    ;;
  -h|--help)
    usage 0
    ;;
  --lock)
    echo "--lock has been removed; installs now record their state automatically." >&2
    usage
    ;;
esac

if [ "$action" = prune ]; then
  case "${1-}" in
    --yes)
      assume_yes=true
      shift
      ;;
  esac
  if [ "$#" -ne 0 ]; then
    usage
  fi
fi

for command_name in git jq find chmod cp mv mktemp; do
  if ! command -v "$command_name" >/dev/null 2>&1; then
    echo "Required command not found: $command_name" >&2
    exit 69
  fi
done

if command -v shasum >/dev/null 2>&1; then
  hash_backend=shasum
elif command -v sha256sum >/dev/null 2>&1; then
  hash_backend=sha256sum
else
  echo "Required command not found: shasum or sha256sum" >&2
  exit 69
fi

for collection in "$active_dir" "$disabled_dir" "$archived_dir"; do
  if [ ! -d "$collection" ]; then
    echo "Missing skill collection: $collection" >&2
    exit 66
  fi
done

current_commit="$(git -C "$repo_root" rev-parse --verify HEAD)"
installed_at="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
work_dir="$(mktemp -d "${TMPDIR:-/tmp}/agent-skills.XXXXXX")"
state="$work_dir/state.json"
manifest="$work_dir/manifest.json"
file_list="$work_dir/files.txt"
source_manifest="$work_dir/source-manifest.json"
destination_manifest="$work_dir/destination-manifest.json"

cleanup() {
  rm -rf "$work_dir"
}
trap cleanup EXIT

if [ -f "$lock_file" ]; then
  if ! jq -e --arg source "$repo_root" '
      if type != "object" or (.installs | type) != "array" then
        error("invalid installer state")
      else
        .
      end
      | .version = 2
      | .source = $source
      | .installs |= map(
          .files = (.files // [])
          | .source_dirty = (.source_dirty // false)
        )
    ' "$lock_file" > "$state"; then
    echo "Invalid installer state: $lock_file" >&2
    exit 65
  fi
else
  jq -n --arg source "$repo_root" '{
    version: 2,
    source: $source,
    installs: []
  }' > "$state"
fi

active_skills=()
shopt -s nullglob
for source in "$active_dir"/*; do
  if [ -d "$source" ] && [ -f "$source/SKILL.md" ]; then
    active_skills+=("${source##*/}")
  fi
done
shopt -u nullglob

validate_skill_name() {
  local skill=$1
  case "$skill" in
    ''|.|..|*[!A-Za-z0-9._-]*)
      echo "Invalid skill name: $skill" >&2
      return 1
      ;;
  esac
}

validate_layout() {
  local collection source skill

  shopt -s nullglob
  for collection in "$active_dir" "$disabled_dir" "$archived_dir"; do
    for source in "$collection"/*; do
      if [ ! -d "$source" ] || [ -L "$source" ]; then
        echo "Unexpected entry in skill collection: $source" >&2
        return 1
      fi
      skill=${source##*/}
      validate_skill_name "$skill" || return
      if [ ! -f "$source/SKILL.md" ]; then
        echo "Skill directory is missing SKILL.md: $source" >&2
        return 1
      fi
      if { [ "$collection" != "$active_dir" ] && [ -e "$active_dir/$skill" ]; } ||
        { [ "$collection" != "$disabled_dir" ] && [ -e "$disabled_dir/$skill" ]; } ||
        { [ "$collection" != "$archived_dir" ] && [ -e "$archived_dir/$skill" ]; }; then
        echo "Skill exists in more than one collection: $skill" >&2
        return 1
      fi
    done
  done
  shopt -u nullglob
}

validate_layout

selected=("$@")
if [ "${#selected[@]}" -gt 0 ]; then
  for skill in "${selected[@]}"; do
    validate_skill_name "$skill"
    if [ ! -f "$active_dir/$skill/SKILL.md" ]; then
      echo "Unknown active skill: $skill" >&2
      exit 66
    fi
  done
fi

is_selected() {
  local skill=$1 wanted
  if [ "${#selected[@]}" -eq 0 ]; then
    return 0
  fi
  for wanted in "${selected[@]}"; do
    if [ "$wanted" = "$skill" ]; then
      return 0
    fi
  done
  return 1
}

is_active() {
  local skill=$1
  [ -f "$active_dir/$skill/SKILL.md" ]
}

path_exists() {
  [ -e "$1" ] || [ -L "$1" ]
}

is_managed() {
  local skill=$1 destination=$2
  jq -e --arg skill "$skill" --arg destination "$destination" '
    [.installs[]
      | select(.skill == $skill and .destination == $destination)]
    | length > 0
  ' "$state" >/dev/null
}

inactive_collection() {
  local skill=$1
  if [ -f "$disabled_dir/$skill/SKILL.md" ]; then
    printf 'disabled'
  elif [ -f "$archived_dir/$skill/SKILL.md" ]; then
    printf 'archived'
  else
    printf 'not in this repository'
  fi
}

hash_file() {
  local file=$1
  if [ "$hash_backend" = shasum ]; then
    shasum -a 256 "$file" | awk '{print $1}'
  else
    sha256sum "$file" | awk '{print $1}'
  fi
}

build_manifest() {
  local directory=$1 output=$2 relative file hash executable
  printf '[]\n' > "$manifest" || return

  if ! (
    cd "$directory" &&
      find . -type f -print | sed 's#^\./##' | LC_ALL=C sort > "$file_list"
  ); then
    return 1
  fi

  while IFS= read -r relative; do
    file="$directory/$relative"
    hash="$(hash_file "$file")" || return
    executable=false
    if [ -x "$file" ]; then
      executable=true
    fi
    jq -c --arg path "$relative" --arg sha256 "$hash" \
      --argjson executable "$executable" \
      '. + [{path: $path, sha256: $sha256, executable: $executable}]' \
      "$manifest" > "$manifest.next" || return
    mv "$manifest.next" "$manifest" || return
  done < "$file_list"

  jq -S . "$manifest" > "$output" || return
}

normalize_permissions() {
  local directory=$1
  find "$directory" -type d -exec chmod 0755 {} + || return
  find "$directory" -type f \
    \( -perm -u+x -o -perm -g+x -o -perm -o+x \) \
    -exec chmod 0755 {} + || return
  find "$directory" -type f \
    ! \( -perm -u+x -o -perm -g+x -o -perm -o+x \) \
    -exec chmod 0644 {} + || return
}

record_install() {
  local skill=$1 destination=$2 source_dirty=false
  build_manifest "$destination" "$destination_manifest" || return

  if [ -n "$(git -C "$repo_root" status --porcelain --untracked-files=all -- \
    "skills/active/$skill")" ]; then
    source_dirty=true
  fi

  jq -c --arg skill "$skill" --arg destination "$destination" \
    --arg source_commit "$current_commit" --arg installed_at "$installed_at" \
    --argjson source_dirty "$source_dirty" --slurpfile files "$destination_manifest" '
      .installs |= map(
        select(.skill != $skill or .destination != $destination)
      ) + [{
        skill: $skill,
        destination: $destination,
        source_commit: $source_commit,
        source_dirty: $source_dirty,
        installed_at: $installed_at,
        files: $files[0]
      }]
    ' "$state" > "$state.next" || return
  mv "$state.next" "$state" || return
}

remove_stage() {
  local stage_root=$1 target=$2
  case "$stage_root" in
    "$target"/.agent-skills-install.*)
      rm -rf "$stage_root"
      ;;
    *)
      echo "Refusing to remove unexpected staging path: $stage_root" >&2
      return 1
      ;;
  esac
}

install_skill() {
  local skill=$1 target=$2 label=$3
  local destination="$target/$skill" source="$active_dir/$skill"
  local stage_root staged previous had_previous=false

  mkdir -p "$target"
  stage_root="$(mktemp -d "$target/.agent-skills-install.XXXXXX")"
  staged="$stage_root/new"
  previous="$stage_root/previous"

  if ! cp -R "$source" "$staged"; then
    remove_stage "$stage_root" "$target"
    echo "Failed to stage $skill for $label" >&2
    return 1
  fi
  if ! normalize_permissions "$staged"; then
    remove_stage "$stage_root" "$target"
    echo "Failed to normalize permissions for $skill" >&2
    return 1
  fi

  if path_exists "$destination"; then
    if ! is_managed "$skill" "$destination"; then
      echo "Warning: replacing unmanaged $label skill at $destination" >&2
    fi
    echo "Replacing $label/$skill"
    if ! mv "$destination" "$previous"; then
      remove_stage "$stage_root" "$target"
      echo "Failed to preserve the existing $label/$skill" >&2
      return 1
    fi
    had_previous=true
  else
    echo "Installing $label/$skill"
  fi

  if ! mv "$staged" "$destination"; then
    if [ "$had_previous" = true ]; then
      if ! mv "$previous" "$destination"; then
        echo "Failed to restore $destination; previous copy remains at $previous" >&2
        return 1
      fi
    fi
    remove_stage "$stage_root" "$target"
    echo "Failed to activate $label/$skill" >&2
    return 1
  fi

  if ! record_install "$skill" "$destination"; then
    echo "Installed $label/$skill, but failed to record its state." >&2
    if [ "$had_previous" = true ]; then
      echo "The previous copy remains at $previous" >&2
    fi
    return 1
  fi
  remove_stage "$stage_root" "$target"
}

warn_inactive_installations() {
  local index target label destination skill collection ownership
  for index in "${!targets[@]}"; do
    target=${targets[$index]}
    label=${target_labels[$index]}
    [ -d "$target" ] || continue
    while IFS= read -r -d '' destination; do
      skill=${destination##*/}
      is_active "$skill" && continue
      collection="$(inactive_collection "$skill")"
      ownership=unmanaged
      if is_managed "$skill" "$destination"; then
        ownership=managed
      fi
      echo "Warning: $label/$skill is installed but $collection ($ownership)." >&2
    done < <(find "$target" -mindepth 1 -maxdepth 1 ! -name '.*' -print0)
  done
}

show_status() {
  local skill index target label destination managed_note collection ownership
  local inactive_found=false

  echo "Active skills"
  for skill in "${active_skills[@]}"; do
    is_selected "$skill" || continue
    build_manifest "$active_dir/$skill" "$source_manifest"
    for index in "${!targets[@]}"; do
      target=${targets[$index]}
      label=${target_labels[$index]}
      destination="$target/$skill"
      managed_note=
      if ! is_managed "$skill" "$destination"; then
        managed_note="; not yet managed"
      fi

      if ! path_exists "$destination"; then
        printf '  %-10s %s/%s (will install)\n' MISSING "$label" "$skill"
      elif [ -L "$destination" ] || [ ! -d "$destination" ]; then
        printf '  %-10s %s/%s (existing path will be replaced%s)\n' \
          CONFLICT "$label" "$skill" "$managed_note"
      elif ! build_manifest "$destination" "$destination_manifest"; then
        printf '  %-10s %s/%s (could not read installed files)\n' \
          UNREADABLE "$label" "$skill"
      elif cmp -s "$source_manifest" "$destination_manifest"; then
        printf '  %-10s %s/%s%s\n' CURRENT "$label" "$skill" "$managed_note"
      else
        printf '  %-10s %s/%s (will replace%s)\n' \
          OUTDATED "$label" "$skill" "$managed_note"
      fi
    done
  done

  echo
  echo "Installed skills not in active"
  for index in "${!targets[@]}"; do
    target=${targets[$index]}
    label=${target_labels[$index]}
    [ -d "$target" ] || continue
    while IFS= read -r -d '' destination; do
      skill=${destination##*/}
      is_active "$skill" && continue
      inactive_found=true
      collection="$(inactive_collection "$skill")"
      ownership=UNMANAGED
      if is_managed "$skill" "$destination"; then
        ownership=STALE
      fi
      printf '  %-10s %s/%s (%s)\n' "$ownership" "$label" "$skill" "$collection"
    done < <(find "$target" -mindepth 1 -maxdepth 1 ! -name '.*' -print0)
  done
  if [ "$inactive_found" = false ]; then
    echo "  None"
  fi

  echo
  echo "STALE entries can be removed with: ./scripts/install.sh prune"
  echo "UNMANAGED entries are never removed automatically."
}

write_state() {
  jq -S . "$state" > "$lock_file.tmp"
  mv "$lock_file.tmp" "$lock_file"
}

prune_stale() {
  local index target label destination skill collection answer
  local candidate_index expected
  local -a prune_destinations=() prune_skills=() prune_targets=() prune_labels=()

  for index in "${!targets[@]}"; do
    target=${targets[$index]}
    label=${target_labels[$index]}
    [ -d "$target" ] || continue
    while IFS= read -r -d '' destination; do
      skill=${destination##*/}
      is_active "$skill" && continue
      if is_managed "$skill" "$destination"; then
        prune_destinations+=("$destination")
        prune_skills+=("$skill")
        prune_targets+=("$target")
        prune_labels+=("$label")
      fi
    done < <(find "$target" -mindepth 1 -maxdepth 1 ! -name '.*' -print0)
  done

  if [ "${#prune_destinations[@]}" -eq 0 ]; then
    echo "No stale managed skills to remove."
    warn_inactive_installations
    return
  fi

  echo "Stale managed skills"
  for candidate_index in "${!prune_destinations[@]}"; do
    skill=${prune_skills[$candidate_index]}
    label=${prune_labels[$candidate_index]}
    collection="$(inactive_collection "$skill")"
    echo "  $label/$skill ($collection)"
  done

  if [ "$assume_yes" = false ]; then
    if [ ! -t 0 ]; then
      echo "Not pruning without confirmation; rerun with 'prune --yes'." >&2
      return 3
    fi
    printf 'Remove these installed copies? [y/N] '
    IFS= read -r answer
    case "$answer" in
      y|Y|yes|YES)
        ;;
      *)
        echo "Nothing removed."
        return
        ;;
    esac
  fi

  for candidate_index in "${!prune_destinations[@]}"; do
    destination=${prune_destinations[$candidate_index]}
    skill=${prune_skills[$candidate_index]}
    target=${prune_targets[$candidate_index]}
    label=${prune_labels[$candidate_index]}
    expected="$target/$skill"
    if [ "$destination" != "$expected" ]; then
      echo "Refusing to remove unexpected destination: $destination" >&2
      return 1
    fi
    rm -rf "$destination"
    jq -c --arg skill "$skill" --arg destination "$destination" '
      .installs |= map(
        select(.skill != $skill or .destination != $destination)
      )
    ' "$state" > "$state.next"
    mv "$state.next" "$state"
    echo "Removed $label/$skill"
  done
  write_state
  warn_inactive_installations
}

case "$action" in
  status)
    show_status
    ;;
  prune)
    prune_stale
    ;;
  install)
    warn_inactive_installations
    installed_count=0
    for skill in "${active_skills[@]}"; do
      is_selected "$skill" || continue
      for index in "${!targets[@]}"; do
        install_skill "$skill" "${targets[$index]}" "${target_labels[$index]}"
      done
      installed_count=$((installed_count + 1))
    done
    write_state
    echo "Installed $installed_count active skill(s); base commit $current_commit."
    if [ -n "$(git -C "$repo_root" status --porcelain --untracked-files=all -- skills/active)" ]; then
      echo "Warning: installed skill content includes uncommitted changes; state records source_dirty=true." >&2
    fi
    ;;
esac
