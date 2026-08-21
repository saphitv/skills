# agent-skills

Personal Codex and Claude Code skills. The repository is the source of truth; `install.sh` publishes reviewed revisions into each agent account.

## Layout

```text
skills/<name>/SKILL.md
lock.json
scripts/install.sh
```

Each skill owns a complete directory. Supporting scripts and references stay beside `SKILL.md`.

## Install

Install every locked skill for both agents:

```sh
./scripts/install.sh
```

Install selected skills:

```sh
./scripts/install.sh unslop research
```

Install into alternate account roots:

```sh
CODEX_HOME="$HOME/.codex-work" \
CLAUDE_CONFIG_DIR="$HOME/.claude-work" \
./scripts/install.sh
```

The installer copies whole skill directories from `skills/` into `$CODEX_HOME/skills` and `$CLAUDE_CONFIG_DIR/skills`. It replaces only paths recorded as installer-owned in `.agent-skills.lock`, leaves unrelated files alone, records installed SHAs and hashes, and is safe to rerun.

## Update flow

1. Edit or add a skill.
2. Commit the change.
3. Run `./scripts/install.sh --lock` to refresh `lock.json` at the current commit.
4. Review the diff.
5. Run the installer normally on other machines.

The lockfile intentionally uses a local commit rather than requiring GitHub. Replace the local source with a tarball download if you later want zero-checkout installation.

## Security

Skills can influence agent behavior and may include executable files or tool permissions. Review every changed skill, script, frontmatter permission, dependency, and hook like code. Never place credentials, tokens, session logs, browser state, or local settings in this repository.
