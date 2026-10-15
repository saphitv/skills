# agent-skills

Personal Codex and Claude Code skills. This repository is the source of truth; the installer publishes a checked-in skill profile into each agent account.

## Profiles

[`profiles/default`](profiles/default) selects `current`, which preserves all 19 repo-managed skills from the existing setup. [`profiles/current.txt`](profiles/current.txt) lists their exact names. [`profiles/pstack.txt`](profiles/pstack.txt) selects only the 16 installed pstack skills and companions. It is the installed subset, not the entire upstream pstack plugin.

With no skill names or profile option, installation, status, and pruning use the default profile:

```sh
./scripts/install.sh status
./scripts/install.sh
```

Select another profile for one command:

```sh
./scripts/install.sh status --profile pstack
./scripts/install.sh install --profile pstack
```

Use `--profile all` to select every skill in `skills/active/`. Explicit skill names override the default profile. Profile options and explicit skill names cannot be combined.

A profile contains one active skill name per line. Blank lines and lines starting with `#` are ignored. Missing, empty, duplicate, or unavailable entries fail before installation or pruning. To change the shared default, edit `profiles/default` and commit it. To remove a skill from a profile, remove its line, then inspect `status`; installation alone never removes existing copies.

## Current skill inventory

The `current` profile contains these 19 skills. Automatic discovery means the agent can select a skill when its task matches. It does not mean every skill runs on every turn. `interrogate` requires an explicit request in both Codex and Claude Code.

| Skill | Purpose |
| --- | --- |
| `arena` | Compare parallel candidate solutions and combine the strongest parts. |
| `blast-radius` | Trace effects beyond a diff and verify concrete risks. |
| `how` | Explain runtime behavior and code ownership. |
| `interrogate` | Run independent model reviews and return a verdict. Manual only. |
| `principle-boundary-discipline` | Validate external inputs at system boundaries. |
| `principle-encode-lessons-in-structure` | Turn recurring corrections into checks or code. |
| `principle-laziness-protocol` | Prefer the smallest useful change and fewer abstractions. |
| `principle-prove-it-works` | Verify the real artifact before declaring completion. |
| `principle-redesign-from-first-principles` | Integrate new requirements into the design. |
| `principle-separate-before-serializing-shared-state` | Separate concurrent writers where possible. |
| `principle-type-system-discipline` | Use types to prevent invalid states. |
| `qstack-babysit-pr` | Watch an existing PR through CI and review feedback. |
| `resolving-merge-conflicts` | Resolve an in-progress merge or rebase and run checks. |
| `tdd` | Demonstrate a failing test before a fix when requested or locally practical. |
| `technical-writing` | Write and review technical documentation. |
| `typescript-best-practices` | Apply TypeScript modeling and coding guidance. |
| `unslop` | Remove AI writing patterns. |
| `upload-file` | Publish a file when URL sharing is requested. |
| `why` | Investigate design decisions using historical evidence. |

All entries except `qstack-babysit-pr`, `resolving-merge-conflicts`, and `upload-file` belong to the `pstack` profile. The extras have these origins:

- `qstack-babysit-pr` comes from [hani-q/qstack](https://github.com/hani-q/qstack/tree/main/skills/qstack-babysit-pr), adapted from Theo Browne's workflow. Current upstream pstack also has a [Babysit playbook inside `poteto-mode`](https://github.com/cursor/plugins/blob/main/pstack/skills/poteto-mode/playbooks/babysit.md). That playbook is not included in this repo's installed subset.
- `resolving-merge-conflicts` was retained from the older Matt Pocock collection. [Upstream has archived it](https://github.com/mattpocock/skills/blob/main/docs/engineering/resolving-merge-conflicts.md). It remains in `current` to preserve the existing setup.
- `upload-file` is an existing repository utility, retained in `current` for file sharing.

Before archiving a companion, check its callers. TypeScript guidance references type-system and boundary discipline. Type-system discipline also references encoding lessons in structure. Arena references separation of shared state, laziness, redesign, and verification. Technical writing references unslop. Blast radius references how, why, and arena.

`diagnose-crash`, `omarchy`, and built-in agent skills are supplied separately and are outside these profiles. Use installer status to inspect actual installations. The inventory describes repository selection, not usage frequency.

There is one disabled skill, `explain-diff-html`, and 34 archived skills. List the current collections with:

```sh
rg --files skills -g SKILL.md | sort
```

## Credits

This collection includes skills from, and adaptations inspired by:

- [Matt Pocock's Skills for Real Engineers](https://github.com/mattpocock/skills)
- [hani-q/qstack's PR babysitting skill](https://github.com/hani-q/qstack/tree/main/skills/qstack-babysit-pr), adapted from Theo Browne's skill
- [Lauren Tan (`@poteto`)'s pstack plugin for Cursor](https://github.com/cursor/plugins/tree/main/pstack)

Credit for the original work belongs to their respective authors and contributors.

## Skill lifecycle

```text
skills/
├── active/      Available for profiles or explicit installation
├── disabled/    Kept for temporary removal
└── archived/    Retained for history, but no longer in normal use
```

Every skill owns a complete directory containing `SKILL.md` and any supporting scripts or references. A skill name must exist in only one collection.

To disable or archive a skill, move its whole directory:

```sh
mv skills/active/example skills/disabled/
mv skills/disabled/example skills/archived/
```

Remove its name from any profiles before disabling or archiving it. Move it back to `skills/active/` and add it to a profile when you want it installed again. Disabled and archived skills are never installed.

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
- `STALE`: managed by this installer, but outside the selected profile or active collection.
- `UNMANAGED`: installed outside this installer and outside the selected profile or active collection.

Limit the active part of the report to selected skills with `./scripts/install.sh status unslop how`. Explicit selection compares stale installations against the entire active collection. The stale and unmanaged section remains global so unexpected installations are not hidden.

## Install

Install the default profile into `$CODEX_HOME/skills` and `$CLAUDE_CONFIG_DIR/skills`:

```sh
./scripts/install.sh
```

Install selected active skills:

```sh
./scripts/install.sh unslop how
```

The explicit form `./scripts/install.sh install ...` is equivalent. Alternate account roots are supported:

```sh
CODEX_HOME="$HOME/.codex-work" \
CLAUDE_CONFIG_DIR="$HOME/.claude-work" \
./scripts/install.sh
```

Installation always stages and then replaces the destination for each selected active skill. It warns before replacing an unmanaged destination. Installed skills that are not active are reported but left in place.

## Remove stale installations

Remove copies previously managed by this installer after their source leaves the selected profile or active collection:

```sh
./scripts/install.sh prune
```

The command lists candidates and asks for confirmation. For non-interactive use:

```sh
./scripts/install.sh prune --yes
```

To prune against another profile, use `./scripts/install.sh prune --profile pstack`. Pruning never removes unmanaged skills. Review those with `status` and remove them manually if appropriate.

## Installer state

`.agent-skills.lock.json` records installed destinations, file hashes, executable bits, the base commit, and whether source content had uncommitted changes. It is initialized automatically and remains untracked because destinations differ by account and host.

The installer can be invoked from any working directory. Replacements are prepared beside the destination before the previous copy is moved, so a staging or copy failure leaves the installed version intact.

## Update flow

1. Add or edit a skill in the appropriate collection and update profile membership when needed.
2. Review and commit the change.
3. Run `./scripts/install.sh status`.
4. Run `./scripts/install.sh` to publish the default profile.
5. Optionally run `./scripts/install.sh prune` to remove stale managed copies.

On another machine, pull the committed repo update, then run `./scripts/install.sh status` before installing. Profiles are portable; `.agent-skills.lock.json` remains local to each machine. The installer leaves separately supplied skills in place, so selecting a profile does not guarantee that no other skills are discoverable.

## Security

Skills can influence agent behavior and may include executable files or tool permissions. Review every changed skill, script, frontmatter permission, dependency, and hook like code. Never place credentials, tokens, session logs, browser state, or local settings in this repository.

## Installed pstack skills

The pstack additions come from `cursor/plugins` commit `23e4138daa01c42d4969f7a5465f82704e64f798`. The requested skills are `technical-writing`, `how`, `interrogate`, `blast-radius`, `tdd`, and `typescript-best-practices`. Companions include `why`, `arena`, and the principle skills those workflows reference.

`how`, `why`, `interrogate`, and `arena` use the current harness and live model catalog, with T3 delegation support. They no longer depend on Cursor's Task tool, fixed model slugs, or `pstack-models.mdc`. Multi-model review defaults to two available models. Interrogate remains explicitly invoked in Codex and Claude Code and returns a verdict without applying fixes. Other additions retain automatic discovery for their stated tasks. Unslop also remains automatic.

The archived Matt Pocock TDD skill lives in `skills/archived/matt-pocock-tdd/` to distinguish it from the active pstack `tdd` skill. Its original files are unchanged.

For a complete feature workflow, ask the agent to implement and verify the change, run interrogate and fix confirmed findings, then open the PR and babysit CI and reviews. These steps run together only when requested; they do not imply permission to merge.
