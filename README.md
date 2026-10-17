# agent-skills

Personal Codex and Claude Code skills. This repository is the source of truth; the installer publishes a checked-in skill profile into each agent account.

To update skills, start with [Update skills](#update-skills). [`upstreams.json`](upstreams.json) records the update source, tracked paths, reviewed commit, and local adaptations for every active skill.

## Profiles

[`profiles/default`](profiles/default) selects `current`, which contains 20 active repo-managed skills. [`profiles/current.txt`](profiles/current.txt) lists their exact names. [`profiles/pstack.txt`](profiles/pstack.txt) selects the 19 pstack and P3 skills and companions, including standalone babysitting and session-review workflows. It is the selected subset, not the entire upstream pstack or P3 plugin.

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

The `current` profile contains these 20 skills. Automatic discovery means the agent can select a skill when its task matches. It does not mean every skill runs on every turn. `interrogate`, `reflect`, and `correct` require an explicit request in both Codex and Claude Code.

| Skill | Purpose |
| --- | --- |
| `arena` | Compare parallel candidate solutions and combine the strongest parts. |
| `blast-radius` | Trace effects beyond a diff and verify concrete risks. |
| `correct` | Prevent recurring repo mistakes through architecture, types, linting, and tests. Manual only. |
| `how` | Explain runtime behavior and code ownership. |
| `interrogate` | Run independent model reviews and return a verdict. Manual only. |
| `principle-boundary-discipline` | Validate external inputs at system boundaries. |
| `principle-encode-lessons-in-structure` | Turn recurring corrections into checks or code. |
| `principle-laziness-protocol` | Prefer the smallest useful change and fewer abstractions. |
| `principle-prove-it-works` | Verify the real artifact before declaring completion. |
| `principle-redesign-from-first-principles` | Integrate new requirements into the design. |
| `principle-separate-before-serializing-shared-state` | Separate concurrent writers where possible. |
| `principle-type-system-discipline` | Use types to prevent invalid states. |
| `pstack-babysit-pr` | Drive a PR or stack to merge-ready using pstack's review and CI workflow. |
| `reflect` | Review a session and propose durable skill improvements. Manual only. |
| `tdd` | Demonstrate a failing test before a fix when requested or locally practical. |
| `technical-writing` | Write and review technical documentation. |
| `typescript-best-practices` | Apply TypeScript modeling and coding guidance. |
| `unslop` | Remove AI writing patterns. |
| `upload-file` | Publish a file when URL sharing is requested. |
| `why` | Investigate design decisions using historical evidence. |

All entries except `upload-file` belong to the `pstack` profile. `upload-file` is an existing repository utility retained in `current` for file sharing.

After a substantial session with reusable lessons, ask "Use reflect to review this session." Reflection uses three reviewer lenses and a synthesizer, then presents proposed skill edits for approval. It does not automatically change skills or file backlog issues. Chat length alone is not a reason to run it.

Use "Run correct on the recurring mistakes in this repo" when you want repository fixes that prevent a demonstrated class of mistakes. `correct` is manual-only, as in P3 upstream. The automatic `principle-encode-lessons-in-structure` guidance remains available during ordinary work; it does not start the full `correct` audit on every correction.

`qstack-babysit-pr`, from [hani-q/qstack](https://github.com/hani-q/qstack/tree/main/skills/qstack-babysit-pr) and adapted from Theo Browne's workflow, is archived. Its replacement, `pstack-babysit-pr`, is included in both profiles.

`resolving-merge-conflicts` from the older Matt Pocock collection is archived and excluded from both profiles. [Upstream has also archived it](https://github.com/mattpocock/skills/blob/main/docs/engineering/resolving-merge-conflicts.md).

Before archiving a companion, check its callers. TypeScript guidance references type-system and boundary discipline. Type-system discipline also references encoding lessons in structure. Arena references separation of shared state, laziness, redesign, and verification. Technical writing references unslop. Blast radius references how, why, and arena.

`diagnose-crash`, `omarchy`, and built-in agent skills are supplied separately and are outside these profiles. Use installer status to inspect actual installations. The inventory describes repository selection, not usage frequency.

There is one disabled skill, `explain-diff-html`, and 36 archived skills. List the current collections with:

```sh
rg --files skills -g SKILL.md | sort
```

## Credits

This collection includes skills from, and adaptations inspired by:

- [Matt Pocock's Skills for Real Engineers](https://github.com/mattpocock/skills)
- [hani-q/qstack's PR babysitting skill](https://github.com/hani-q/qstack/tree/main/skills/qstack-babysit-pr), adapted from Theo Browne's skill
- [Lauren Tan (`@poteto`)'s pstack plugin for Cursor](https://github.com/cursor/plugins/tree/main/pstack)
- [Uzair Ansar's P3 Stack](https://github.com/uzairansaruzi/p3-stack), the T3 Code port of pstack

Credit for the original work belongs to their respective authors and contributors.

P3-following skills retain both Lauren Tan's original pstack credit and Uzair Ansar's T3 adaptation credit. Each externally sourced active skill bundles its upstream MIT license. Update-source assignments describe future maintenance; the [import history](#import-history-and-local-adaptations) records where earlier versions came from.

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

## Update skills

When asked to "update the skills", use [`upstreams.json`](upstreams.json) as the authoritative update map. Every active skill has one update source:

| Update source | Skills |
| --- | --- |
| [P3 Stack](https://github.com/uzairansaruzi/p3-stack) | `arena`, `how`, `why`, `interrogate`, `reflect`, `correct`, and `pstack-babysit-pr` |
| [Original pstack](https://github.com/cursor/plugins/tree/main/pstack) | `blast-radius`, all seven `principle-*` skills, `tdd`, `technical-writing`, `typescript-best-practices`, and `unslop` |
| This repository | `upload-file` |

P3 supplies the workflows that depend on delegation, session history, and PR monitoring. Original pstack supplies the general development and writing practices. Installation profiles can contain skills from both sources. The `pstack` profile name is an installation selection, not an upstream assignment.

### Find upstream changes

Run the read-only checker from the repository root:

```sh
python3 scripts/check-upstreams.py
```

It checks each skill's recorded paths at its `reviewed_commit` against the configured upstream branch. Directory paths include all supporting files. The babysitter tracks its P3 playbook and review rubric separately. License changes are tracked too.

The report uses these statuses:

- `REVIEW`: Tracked upstream files changed. Inspect the listed paths and comparison link before deciding what to incorporate.
- `CURRENT`: Tracked upstream files are unchanged since the recorded review. This says nothing about installed copies.
- `LOCAL`: The skill has no configured external update source.
- `ERROR`: Coverage, source paths, or GitHub access could not be verified. The checker exits nonzero; do not report the affected skills as current.

The checker never writes files or installs skills. An upstream change is a review candidate, not proof that a local adaptation is outdated. Public GitHub access needs no token; the checker uses `GH_TOKEN` or `GITHUB_TOKEN` when supplied.

To check selected skills, pass their names. To validate coverage without network access, use `--validate`:

```sh
python3 scripts/check-upstreams.py how unslop
python3 scripts/check-upstreams.py --validate
```

### Apply reviewed changes

1. Read the skill's `adaptations` in `upstreams.json`. Fetch every tracked path from its assigned upstream, including supporting references and licenses.
2. Compare the recorded upstream revision with the new upstream revision. Integrate relevant changes into the local files. Preserve the documented invocation policy, live model selection, cross-agent support, and authorization boundaries.
3. Record intentional omissions in `adaptations`. Advance that skill's `reviewed_commit` only after reviewing all its tracked paths. The commit is a review baseline; local files can intentionally differ from it.
4. Validate the map and run `python3 -B tests/upstreams_test.py`. Validate any touched skills with the available skill validator. Inspect the final diff.
5. Run `./scripts/install.sh status`, then `./scripts/install.sh` to publish the selected profile. Run status again to verify installed copies match the repository.

Keep historical source metadata and original credits when changing update sources. Never copy a whole upstream plugin over this collection. Keep the existing skill names and selected companions unless the task calls for a migration.

Add an upstream entry when activating a skill. Remove its entry when disabling or archiving it, and update profile membership. The coverage check rejects missing and inactive entries. Disabled, archived, and separately supplied skills are outside a normal update request. Prune stale managed installations only as a separate lifecycle action after reviewing status.

On another machine, pull the committed repo update, then run `./scripts/install.sh status` before installing. Profiles are portable; `.agent-skills.lock.json` remains local to each machine. The installer leaves separately supplied skills in place, so selecting a profile does not guarantee that no other skills are discoverable.

## Security

Skills can influence agent behavior and may include executable files or tool permissions. Review every changed skill, script, frontmatter permission, dependency, and hook like code. Never place credentials, tokens, session logs, browser state, or local settings in this repository.

## Import history and local adaptations

The initial pstack batch came from `cursor/plugins` commit `23e4138daa01c42d4969f7a5465f82704e64f798`. It included `technical-writing`, `how`, `interrogate`, `blast-radius`, `tdd`, and `typescript-best-practices`, plus `why`, `arena`, and the referenced principle companions. Future updates follow the assignments in `upstreams.json`; this paragraph records the historical import.

`reflect` and `correct` come from [P3 Stack](https://github.com/uzairansaruzi/p3-stack/tree/09909ebb5c0125e27fad3e57d96b81e832696d69), commit `09909ebb5c0125e27fad3e57d96b81e832696d69`. Their manual invocation policy is preserved for both agents. The selected-set adaptation lets reflection run without `setup-p3`, `p3-models.md`, or the full `p3-mode` authoring playbook. It uses live model discovery and the available skill-authoring workflow, scopes transcript reads to the requested session, and keeps external backlog filing within the user's authorization.

`pstack-babysit-pr` was initially adapted from the [pstack Babysit playbook](https://github.com/cursor/plugins/blob/99743e9c151c8537cbbf1f98bb38f34ef3368453/pstack/skills/poteto-mode/playbooks/babysit.md) and its review-triage rubric at commit `99743e9c151c8537cbbf1f98bb38f34ef3368453`. It now follows the [P3 Babysit playbook](https://github.com/uzairansaruzi/p3-stack/blob/09909ebb5c0125e27fad3e57d96b81e832696d69/skills/p3-mode/playbooks/babysit.md) and its rubric, reviewed at commit `09909ebb5c0125e27fad3e57d96b81e832696d69`. Its existing name is preserved. It supports one-pass status, review-only work, background monitoring, and driving a PR or stack to merge-ready. Stack work proceeds from the lowest unmerged PR upward. Babysitting leaves rebases to the branch owner and does not authorize merging.

In T3, the adapted skill uses `watch_pull_request`, yields while waiting, and stops its watches before handing work back. Outside T3, it uses available host monitoring. It does not require Cursor's `/loop`, the upstream watcher executable, or the rest of `poteto-mode`. Use it with requests such as "babysit this PR", "check on PR X", or "address the review comments". It starts when requested, not merely when a PR opens.

`how`, `why`, `interrogate`, and `arena` now follow P3, reviewed at commit `09909ebb5c0125e27fad3e57d96b81e832696d69`. Their prompts preserve P3's self-contained briefs and read-only research boundaries. Local adaptations use the current harness and live model catalog, honor configured `p3-models.md` roles when present, and work without installing `setup-p3` or the full P3 plugin. Separate child checkouts use `delegate_task` isolation rather than top-level conversations. Multi-model review defaults to two available models. Interrogate remains explicitly invoked in Codex and Claude Code and returns a verdict without applying fixes. Other additions retain automatic discovery for their stated tasks. Unslop also remains automatic.

The archived Matt Pocock TDD skill lives in `skills/archived/matt-pocock-tdd/` to distinguish it from the active pstack `tdd` skill. Its original files are unchanged.

For a complete feature workflow, ask the agent to implement and verify the change, run interrogate and fix confirmed findings, then open the PR and babysit CI and reviews. These steps run together only when requested; they do not imply permission to merge.
