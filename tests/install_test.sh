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
  "$test_root/codex/skills/unslop" \
  "$test_root/codex/skills/extra-skill" \
  "$test_root/claude/skills"
touch \
  "$test_root/codex/skills/unslop/user-file" \
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
  run_installer unslop upload-file
} 2>&1)"
assert_contains "$install_output" "Warning: replacing unmanaged Codex skill"
assert_contains "$install_output" "Installed 2 active skill(s)"

[ -f "$test_root/codex/skills/unslop/SKILL.md" ] || fail "Codex skill was not installed"
[ -f "$test_root/claude/skills/unslop/SKILL.md" ] || fail "Claude skill was not installed"
[ ! -e "$test_root/codex/skills/unslop/user-file" ] || fail "active skill was not replaced"
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

status_output="$(run_installer status unslop 2>&1)"
assert_contains "$status_output" "CURRENT    Codex/unslop"
assert_contains "$status_output" "CURRENT    Claude/unslop"
assert_contains "$status_output" "UNMANAGED  Codex/extra-skill"

touch "$test_root/codex/skills/unslop/local-change"
status_output="$(run_installer status unslop 2>&1)"
assert_contains "$status_output" "OUTDATED   Codex/unslop"
assert_contains "$status_output" "CURRENT    Claude/unslop"

mv \
  "$test_root/repo/skills/active/unslop" \
  "$test_root/repo/skills/disabled/unslop"
status_output="$(run_installer status --profile all 2>&1)"
assert_contains "$status_output" "STALE      Codex/unslop (disabled)"
assert_contains "$status_output" "STALE      Claude/unslop (disabled)"

set +e
prune_output="$(run_installer prune --profile all 2>&1)"
prune_status=$?
set -e
[ "$prune_status" -eq 3 ] || fail "non-interactive prune should require --yes"
assert_contains "$prune_output" "rerun with 'prune --yes'"
[ -d "$test_root/codex/skills/unslop" ] || fail "unconfirmed prune removed a skill"

prune_output="$(run_installer prune --profile all --yes 2>&1)"
assert_contains "$prune_output" "Removed Codex/unslop"
assert_contains "$prune_output" "Removed Claude/unslop"
[ ! -e "$test_root/codex/skills/unslop" ] || fail "stale Codex skill was not removed"
[ ! -e "$test_root/claude/skills/unslop" ] || fail "stale Claude skill was not removed"
[ -e "$test_root/codex/skills/extra-skill/user-file" ] || fail "prune removed an unmanaged skill"
[ -d "$test_root/codex/skills/upload-file" ] || fail "prune removed an active skill"
mv "$test_root/repo/skills/disabled/unslop" "$test_root/repo/skills/active/unslop"

# Simulate an existing managed qstack installation before the profile migrates.
mv "$test_root/repo/skills/archived/qstack-babysit-pr" "$test_root/repo/skills/active/qstack-babysit-pr"
install_output="$(run_installer qstack-babysit-pr 2>&1)"
assert_contains "$install_output" "Installed 1 active skill(s)"
mv "$test_root/repo/skills/active/qstack-babysit-pr" "$test_root/repo/skills/archived/qstack-babysit-pr"

# The default profile installs the maintained selection in both accounts.
install_output="$(run_installer 2>&1)"
assert_contains "$install_output" "Installed 45 active skill(s)"
for account in codex claude; do
  while IFS= read -r skill; do
    [ -f "$test_root/$account/skills/$skill/SKILL.md" ] || fail "default profile omitted $account/$skill"
    diff -r "$test_root/repo/skills/active/$skill" "$test_root/$account/skills/$skill" >/dev/null ||
      fail "installed $account/$skill differs from source"
  done < "$test_root/repo/profiles/current.txt"
done
status_output="$(run_installer status 2>&1)"
assert_contains "$status_output" "Active skills (profile: current)"
assert_contains "$status_output" "CURRENT    Codex/pstack-babysit-pr"
assert_contains "$status_output" "STALE      Codex/qstack-babysit-pr (archived)"
assert_contains "$status_output" "STALE      Claude/qstack-babysit-pr (archived)"
prune_output="$(run_installer prune --yes 2>&1)"
assert_contains "$prune_output" "Removed Codex/qstack-babysit-pr"
for account in codex claude; do
  for resource in playbooks/feature.md playbooks/shipping.md agents/p3-agent.md agents/comment-sicko.md references/delegation.md LICENSE; do
    [ -f "$test_root/$account/skills/p3-mode/$resource" ] || fail "P3 entrypoint lost $resource"
  done
  [ ! -e "$test_root/$account/skills/qstack-babysit-pr" ] || fail "archive prune retained qstack"
  [ -f "$test_root/$account/skills/pstack-babysit-pr/references/review-triage.md" ] ||
    fail "replacement babysitter lost its triage reference"
done

# Profile installation reports existing extras, but only prune removes them.
install_output="$(run_installer install --profile pstack 2>&1)"
assert_contains "$install_output" "Installed 44 active skill(s)"
[ -f "$test_root/codex/skills/upload-file/SKILL.md" ] || fail "profile install removed an extra"
status_output="$(run_installer status --profile pstack 2>&1)"
assert_contains "$status_output" "Active skills (profile: pstack)"
assert_contains "$status_output" "CURRENT    Codex/pstack-babysit-pr"
assert_contains "$status_output" "STALE      Claude/upload-file (outside profile pstack)"
assert_contains "$status_output" "prune --profile pstack"
prune_output="$(run_installer prune --profile pstack --yes 2>&1)"
assert_contains "$prune_output" "Removed Codex/upload-file"
for account in codex claude; do
  [ ! -e "$test_root/$account/skills/upload-file" ] || fail "profile prune retained $account/upload-file"
  for manual_skill in interrogate reflect correct p3-mode; do
    [ -f "$test_root/$account/skills/$manual_skill/SKILL.md" ] || fail "profile prune removed $manual_skill"
    grep -q 'allow_implicit_invocation: false' "$test_root/$account/skills/$manual_skill/agents/openai.yaml" ||
      fail "profile installation changed manual invocation for $manual_skill"
    grep -q '^disable-model-invocation: true$' "$test_root/$account/skills/$manual_skill/SKILL.md" ||
      fail "profile installation changed Claude invocation for $manual_skill"
  done
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
  [ -f "$test_root/codex/skills/unslop/SKILL.md" ] || fail "invalid profile removed an installed skill"
  [ -e "$test_root/codex/skills/extra-skill/user-file" ] || fail "invalid profile changed an unmanaged skill"
  printf '%s' "$output"
}

output="$(assert_profile_rejected install --profile missing)"
assert_contains "$output" "Unknown profile: missing"
printf 'unslop\nmissing\n' > "$test_root/repo/profiles/invalid.txt"
output="$(assert_profile_rejected install --profile invalid)"
assert_contains "$output" "unavailable active skill: missing"
printf 'unslop\nunslop\n' > "$test_root/repo/profiles/invalid.txt"
output="$(assert_profile_rejected prune --yes --profile invalid)"
assert_contains "$output" "Duplicate skill"
printf '# Empty profile\n\n' > "$test_root/repo/profiles/invalid.txt"
output="$(assert_profile_rejected install --profile invalid)"
assert_contains "$output" "has no skills"
output="$(assert_profile_rejected install --profile ../outside)"
assert_contains "$output" "Invalid skill name"
output="$(assert_profile_rejected install --profile pstack unslop)"
assert_contains "$output" "Usage:"

echo "Installer lifecycle tests passed."
