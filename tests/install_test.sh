#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
test_root="$(mktemp -d "${TMPDIR:-/tmp}/agent-skills-test.XXXXXX")"

cleanup() {
  case "$test_root" in
    "${TMPDIR:-/tmp}"/agent-skills-test.*)
      rm -rf "$test_root"
      ;;
  esac
}
trap cleanup EXIT

fail() {
  echo "FAIL: $*" >&2
  exit 1
}

assert_contains() {
  local output=$1 expected=$2
  case "$output" in
    *"$expected"*)
      ;;
    *)
      fail "expected output to contain: $expected"
      ;;
  esac
}

cp -R "$repo_root" "$test_root/repo"
rm -f "$test_root/repo/.agent-skills.lock.json"
mkdir -p \
  "$test_root/outside" \
  "$test_root/codex/skills/file-pr" \
  "$test_root/codex/skills/extra-skill" \
  "$test_root/claude/skills"
touch \
  "$test_root/codex/skills/file-pr/user-file" \
  "$test_root/codex/skills/extra-skill/user-file"
# Match T3's symlinked Codex skill directory alongside a plain Claude directory.
mv "$test_root/codex/skills" "$test_root/codex-skills"
ln -s "$test_root/codex-skills" "$test_root/codex/skills"

installer="$test_root/repo/scripts/install.sh"
run_installer() {
  CODEX_HOME="$test_root/codex" \
    CLAUDE_CONFIG_DIR="$test_root/claude" \
    "$installer" "$@"
}

install_output="$({
  cd "$test_root/outside"
  run_installer file-pr upload-file
} 2>&1)"
assert_contains "$install_output" "Warning: replacing unmanaged Codex skill"
assert_contains "$install_output" "Installed 2 active skill(s)"

[ -f "$test_root/codex/skills/file-pr/SKILL.md" ] || fail "Codex skill was not installed"
[ -f "$test_root/claude/skills/file-pr/SKILL.md" ] || fail "Claude skill was not installed"
[ ! -e "$test_root/codex/skills/file-pr/user-file" ] || fail "active skill was not replaced"
[ -x "$test_root/codex/skills/upload-file/scripts/upload" ] || fail "executable mode was lost"
[ -e "$test_root/codex/skills/extra-skill/user-file" ] || fail "unmanaged skill was changed"

jq -e '
  .version == 2
  and (.installs | length == 4)
  and all(.installs[]; (.source_dirty | type) == "boolean")
  and any(
    .installs[];
    .skill == "upload-file"
    and any(.files[]; .path == "scripts/upload" and .executable == true)
  )
' "$test_root/repo/.agent-skills.lock.json" >/dev/null || fail "installer state is incomplete"

status_output="$(run_installer status file-pr 2>&1)"
assert_contains "$status_output" "CURRENT    Codex/file-pr"
assert_contains "$status_output" "CURRENT    Claude/file-pr"
assert_contains "$status_output" "UNMANAGED  Codex/extra-skill"

touch "$test_root/codex/skills/file-pr/local-change"
status_output="$(run_installer status file-pr 2>&1)"
assert_contains "$status_output" "OUTDATED   Codex/file-pr"
assert_contains "$status_output" "CURRENT    Claude/file-pr"

mv \
  "$test_root/repo/skills/active/file-pr" \
  "$test_root/repo/skills/disabled/file-pr"
status_output="$(run_installer status --profile all 2>&1)"
assert_contains "$status_output" "STALE      Codex/file-pr (disabled)"
assert_contains "$status_output" "STALE      Claude/file-pr (disabled)"

set +e
prune_output="$(run_installer prune --profile all 2>&1)"
prune_status=$?
set -e
[ "$prune_status" -eq 3 ] || fail "non-interactive prune should require --yes"
assert_contains "$prune_output" "rerun with 'prune --yes'"
[ -d "$test_root/codex/skills/file-pr" ] || fail "unconfirmed prune removed a skill"

prune_output="$(run_installer prune --profile all --yes 2>&1)"
assert_contains "$prune_output" "Removed Codex/file-pr"
assert_contains "$prune_output" "Removed Claude/file-pr"
[ ! -e "$test_root/codex/skills/file-pr" ] || fail "stale Codex skill was not removed"
[ ! -e "$test_root/claude/skills/file-pr" ] || fail "stale Claude skill was not removed"
[ -e "$test_root/codex/skills/extra-skill/user-file" ] || fail "prune removed an unmanaged skill"
[ -d "$test_root/codex/skills/upload-file" ] || fail "prune removed an active skill"
mv "$test_root/repo/skills/disabled/file-pr" "$test_root/repo/skills/active/file-pr"

# Simulate an existing managed qstack installation before the profile migrates.
cp -R "$test_root/repo/skills/active/babysit-pr" "$test_root/repo/skills/active/legacy-babysit-pr"
install_output="$(run_installer legacy-babysit-pr 2>&1)"
assert_contains "$install_output" "Installed 1 active skill(s)"
mv "$test_root/repo/skills/active/legacy-babysit-pr" "$test_root/repo/skills/archived/legacy-babysit-pr"

# The default profile installs the maintained selection in both accounts.
install_output="$(run_installer 2>&1)"
assert_contains "$install_output" "Installed 13 active skill(s)"
for account in codex claude; do
  while IFS= read -r skill; do
    [ -f "$test_root/$account/skills/$skill/SKILL.md" ] || fail "default profile omitted $account/$skill"
    diff -r "$test_root/repo/skills/active/$skill" "$test_root/$account/skills/$skill" >/dev/null ||
      fail "installed $account/$skill differs from source"
  done < "$test_root/repo/profiles/current.txt"
done
status_output="$(run_installer status 2>&1)"
assert_contains "$status_output" "Active skills (profile: current)"
assert_contains "$status_output" "CURRENT    Codex/babysit-pr"
assert_contains "$status_output" "STALE      Codex/legacy-babysit-pr (archived)"
assert_contains "$status_output" "STALE      Claude/legacy-babysit-pr (archived)"
prune_output="$(run_installer prune --yes 2>&1)"
assert_contains "$prune_output" "Removed Codex/legacy-babysit-pr"
for account in codex claude; do
  [ -x "$test_root/$account/skills/babysit-pr/scripts/pr-wait" ] || fail "babysitter executable was lost"
  [ -f "$test_root/$account/skills/babysit-pr/LICENSE" ] || fail "upstream license was lost"
  [ ! -e "$test_root/$account/skills/legacy-babysit-pr" ] || fail "archive prune retained legacy skill"
done

# Profile installation reports existing extras, but only prune removes them.
install_output="$(run_installer install --profile tstack 2>&1)"
assert_contains "$install_output" "Installed 9 active skill(s)"
[ -f "$test_root/codex/skills/upload-file/SKILL.md" ] || fail "profile install removed an extra"
status_output="$(run_installer status --profile tstack 2>&1)"
assert_contains "$status_output" "Active skills (profile: tstack)"
assert_contains "$status_output" "CURRENT    Codex/babysit-pr"
assert_contains "$status_output" "STALE      Claude/upload-file (outside profile tstack)"
assert_contains "$status_output" "prune --profile tstack"
prune_output="$(run_installer prune --profile tstack --yes 2>&1)"
assert_contains "$prune_output" "Removed Codex/upload-file"
for account in codex claude; do
  [ ! -e "$test_root/$account/skills/upload-file" ] || fail "profile prune retained $account/upload-file"
  while IFS= read -r skill; do
    [ -f "$test_root/$account/skills/$skill/SKILL.md" ] || fail "profile prune removed $skill"
  done < "$test_root/repo/profiles/tstack.txt"
done
[ -e "$test_root/codex/skills/extra-skill/user-file" ] || fail "profile prune removed an unmanaged skill"

# Explicit selection and the all profile remain available.
status_output="$(run_installer status --profile all 2>&1)"
assert_contains "$status_output" "MISSING    Codex/upload-file"
install_output="$(run_installer upload-file 2>&1)"
assert_contains "$install_output" "Installed 1 active skill(s)"
status_output="$(run_installer status upload-file 2>&1)"
assert_contains "$status_output" "CURRENT    Codex/upload-file"
assert_contains "$status_output" "Active skills (explicit selection)"

# Invalid profiles must fail before changing any installed files or state.
assert_profile_rejected() {
  local output
  cp "$test_root/repo/.agent-skills.lock.json" "$test_root/state-before.json"
  if output="$(run_installer "$@" 2>&1)"; then
    fail "invalid profile command succeeded: $*"
  fi
  cmp -s "$test_root/state-before.json" "$test_root/repo/.agent-skills.lock.json" ||
    fail "invalid profile changed installer state"
  [ -f "$test_root/codex/skills/file-pr/SKILL.md" ] || fail "invalid profile removed an installed skill"
  [ -e "$test_root/codex/skills/extra-skill/user-file" ] || fail "invalid profile changed an unmanaged skill"
  printf '%s' "$output"
}

output="$(assert_profile_rejected install --profile missing)"
assert_contains "$output" "Unknown profile: missing"
printf 'file-pr\nmissing\n' > "$test_root/repo/profiles/invalid.txt"
output="$(assert_profile_rejected install --profile invalid)"
assert_contains "$output" "unavailable active skill: missing"
printf 'file-pr\nfile-pr\n' > "$test_root/repo/profiles/invalid.txt"
output="$(assert_profile_rejected prune --yes --profile invalid)"
assert_contains "$output" "Duplicate skill"
printf '# Empty profile\n\n' > "$test_root/repo/profiles/invalid.txt"
output="$(assert_profile_rejected install --profile invalid)"
assert_contains "$output" "has no skills"
output="$(assert_profile_rejected install --profile ../outside)"
assert_contains "$output" "Invalid skill name"
output="$(assert_profile_rejected install --profile tstack file-pr)"
assert_contains "$output" "Usage:"

echo "Installer lifecycle tests passed."
