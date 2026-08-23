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
status_output="$(run_installer status 2>&1)"
assert_contains "$status_output" "STALE      Codex/unslop (disabled)"
assert_contains "$status_output" "STALE      Claude/unslop (disabled)"

set +e
prune_output="$(run_installer prune 2>&1)"
prune_status=$?
set -e
[ "$prune_status" -eq 3 ] || fail "non-interactive prune should require --yes"
assert_contains "$prune_output" "rerun with 'prune --yes'"
[ -d "$test_root/codex/skills/unslop" ] || fail "unconfirmed prune removed a skill"

prune_output="$(run_installer prune --yes 2>&1)"
assert_contains "$prune_output" "Removed Codex/unslop"
assert_contains "$prune_output" "Removed Claude/unslop"
[ ! -e "$test_root/codex/skills/unslop" ] || fail "stale Codex skill was not removed"
[ ! -e "$test_root/claude/skills/unslop" ] || fail "stale Claude skill was not removed"
[ -e "$test_root/codex/skills/extra-skill/user-file" ] || fail "prune removed an unmanaged skill"
[ -d "$test_root/codex/skills/upload-file" ] || fail "prune removed an active skill"

echo "Installer lifecycle tests passed."
