# agent-skills

Personal Codex and Claude Code skills. This repository is the source of truth; the installer publishes active skills into each agent account.

## Credits

This collection includes skills from, and adaptations inspired by:

- [Matt Pocock's Skills for Real Engineers](https://github.com/mattpocock/skills)
- [hani-q/qstack's PR babysitting skill](https://github.com/hani-q/qstack/tree/main/skills/qstack-babysit-pr), adapted from Theo Browne's skill
- [Lauren Tan (`@poteto`)'s pstack plugin for Cursor](https://github.com/cursor/plugins/tree/main/pstack)

Credit for the original work belongs to their respective authors and contributors.

## Skill lifecycle

```text
skills/
├── active/      Installed by default
├── disabled/    Kept for temporary removal
└── archived/    Retained for history, but no longer in normal use
```

Every skill owns a complete directory containing `SKILL.md` and any supporting scripts or references. A skill name must exist in only one collection.

To disable or archive a skill, move its whole directory:

```sh
mv skills/active/example skills/disabled/
mv skills/disabled/example skills/archived/
```

Move it back to `skills/active/` when you want it installed again. Disabled and archived skills are never installed.

## Inspect installations

Review both agent accounts before changing anything:

```sh
./scripts/install.sh status
```

The report distinguishes:

- `MISSING`: active, but not installed.
- `CURRENT`: installed content matches the active source.
- `OUTDATED`: installed content differs and will be replaced.
- `CONFLICT`: an active skill name is occupied by a file or symlink and will be replaced.
- `STALE`: managed by this installer, but no longer active.
- `UNMANAGED`: installed outside this installer and not active here.

Limit the active part of the report to selected skills with `./scripts/install.sh status unslop research`. The stale and unmanaged section remains global so unexpected installations are not hidden.

## Install

Install every active skill into `$CODEX_HOME/skills` and `$CLAUDE_CONFIG_DIR/skills`:

```sh
./scripts/install.sh
```

Install selected active skills:

```sh
./scripts/install.sh unslop research
```

The explicit form `./scripts/install.sh install ...` is equivalent. Alternate account roots are supported:

```sh
CODEX_HOME="$HOME/.codex-work" \
CLAUDE_CONFIG_DIR="$HOME/.claude-work" \
./scripts/install.sh
```

Installation always stages and then replaces the destination for each selected active skill. It warns before replacing an unmanaged destination. Installed skills that are not active are reported but left in place.

## Remove stale installations

Remove copies previously managed by this installer after their source has moved to `disabled`, `archived`, or out of the repository:

```sh
./scripts/install.sh prune
```

The command lists candidates and asks for confirmation. For non-interactive use:

```sh
./scripts/install.sh prune --yes
```

Pruning never removes unmanaged skills. Review those with `status` and remove them manually if appropriate.

## Installer state

`.agent-skills.lock.json` records installed destinations, file hashes, executable bits, the base commit, and whether source content had uncommitted changes. It is initialized automatically and remains untracked because destinations differ by account and host.

The installer can be invoked from any working directory. Replacements are prepared beside the destination before the previous copy is moved, so a staging or copy failure leaves the installed version intact.

## Update flow

1. Add or edit a skill in the appropriate collection.
2. Review and commit the change.
3. Run `./scripts/install.sh status`.
4. Run `./scripts/install.sh` to publish active skills.
5. Optionally run `./scripts/install.sh prune` to remove stale managed copies.

## Security

Skills can influence agent behavior and may include executable files or tool permissions. Review every changed skill, script, frontmatter permission, dependency, and hook like code. Never place credentials, tokens, session logs, browser state, or local settings in this repository.

## Installed pstack skills

The pstack additions come from `cursor/plugins` commit `23e4138daa01c42d4969f7a5465f82704e64f798`. The requested skills are `technical-writing`, `how`, `interrogate`, `blast-radius`, `tdd`, and `typescript-best-practices`. Companions include `why`, `arena`, and the principle skills those workflows reference.

`how`, `why`, `interrogate`, and `arena` use the current harness and live model catalog, with T3 delegation support. They no longer depend on Cursor's Task tool, fixed model slugs, or `pstack-models.mdc`. Multi-model review defaults to two available models. Interrogate remains explicitly invoked in Codex and Claude Code and returns a verdict without applying fixes. Other additions retain automatic discovery for their stated tasks. Unslop also remains automatic.

The archived Matt Pocock TDD skill lives in `skills/archived/matt-pocock-tdd/` to distinguish it from the active pstack `tdd` skill. Its original files are unchanged.

For a complete feature workflow, ask the agent to implement and verify the change, run interrogate and fix confirmed findings, then open the PR and babysit CI and reviews. These steps run together only when requested; they do not imply permission to merge.
