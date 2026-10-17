# agent-skills

Personal Codex and Claude Code skills. This repository is the source of truth; the installer publishes a checked-in skill profile into each agent account.

To update skills, start with [Update skills](#update-skills). [`upstreams.json`](upstreams.json) records the update source, tracked paths, reviewed commit, and local adaptations for every active skill.

## Profiles

[`profiles/default`](profiles/default) selects `current`, which contains 45 active repo-managed skills. [`profiles/current.txt`](profiles/current.txt) lists their exact names. [`profiles/pstack.txt`](profiles/pstack.txt) selects the 44 pstack and P3 skills and companions, including standalone babysitting and session-review workflows. It includes the `p3-mode` entrypoint and all its bundled playbooks alongside selected companion skills. It does not install every upstream companion.

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

The `current` profile contains 45 skills, including the 24 principles and the core P3 workflows. Automatic discovery means the agent can select a skill when its task matches. It does not mean every skill runs on every turn. P3 entrypoints, newly imported principles, and specialist workflows preserve upstream explicit invocation. Existing automatic companion policies remain unchanged.

| Skill | Purpose |
| --- | --- |
| `architect` | Sketch types, signatures, and module structure before code, then stay in the loop while implementation fills in. |
| `arena` | Spawn N parallel candidates at the same task, pick a base, graft the strongest parts of the losers into it. |
| `benchmark-checklist` | Vet a perf measurement (limiter, tuning, limits, errors, repeatability, relevance, and whether the work happened) before you report or act on it. |
| `blast-radius` | Find what a change could break somewhere else before it ships, beyond the diff, and prove the one fact it's safe because of by running real code instead of writing it up. |
| `correct` | Find the mistakes agents keep repeating in this repo and make each one impossible. |
| `figure-it-out` | Design an auditable playbook when no narrower one fits: a large migration, an ambitious multi-part change, or work a human reviews after stepping away. |
| `how` | Use for \"how does X work\", code walkthroughs before changing something, and placement / ownership / layering questions (\"where should this live\", \"which package owns this\", \"is this the right layer\"). |
| `interrogate` | Use for \"interrogate\", \"adversarial review\", \"multi-model review\", \"challenge this\", \"stress test this code\", \"find blind spots\", or \"tear this apart\". |
| `no-comments` | Spawn Comment Sicko, fix accepted findings, and offer encodings for claimed constraints. |
| `p3-mode` | p3 agent style for concise, detailed responses, deliberate delegation, unslopped prose, simple code, and verified work. |
| `principle-attack-the-premise` | Apply when two or more fixes that share one premise have failed the same gate. |
| `principle-boundary-discipline` | Apply when wiring validation, error handling, or framework adapters. |
| `principle-build-the-lever` | Apply to any non-trivial work, not just bulk work: edits, migrations, analyses, checks. |
| `principle-encode-lessons-in-structure` | Apply when you catch yourself writing the same instruction a second time, or notice a recurring correction. |
| `principle-exhaust-the-design-space` | Apply when facing a novel UI interaction or architectural decision with no precedent in the codebase. |
| `principle-experience-first` | Apply when product, UX, or feature-scope tradeoffs come up. |
| `principle-explain-the-number` | Apply before you trust, report, or act on a number you measured: a speedup, a regression, a throughput, a latency, or an eval result. |
| `principle-fix-root-causes` | Apply when debugging. |
| `principle-foundational-thinking` | Apply before writing logic: choosing core types and data structures, sequencing scaffold-vs-feature work, asking what concurrent actors share. |
| `principle-guard-the-context-window` | Apply when context is filling up: large outputs, long files, repeated reads, fan-out planning. |
| `principle-laziness-protocol` | Apply when refactoring, evaluating diff size, or tempted to add abstractions, layers, or signal threading. |
| `principle-make-operations-idempotent` | Apply when designing commands, lifecycle steps, or processing loops that run amid crashes, restarts, and retries. |
| `principle-migrate-callers-then-delete-legacy-apis` | Apply when introducing a new internal API while old callers still exist. |
| `principle-minimize-reader-load` | Apply when reviewing or shaping code that's hard to trace. |
| `principle-model-the-domain` | Apply when writing stateful logic, or when code branches a lot or repeats a shape assumption across files. |
| `principle-never-block-on-the-human` | Apply when tempted to ask 'should I do X?' on reversible work. |
| `principle-outcome-oriented-execution` | Apply during planned rewrites and migrations with explicit phase boundaries. |
| `principle-prove-it-works` | Apply after completing a task, before declaring done. |
| `principle-redesign-from-first-principles` | Apply when integrating a new requirement into an existing design. |
| `principle-separate-before-serializing-shared-state` | Apply when concurrent actors might write to the same file, branch, key, or state object. |
| `principle-sequence-verifiable-units` | Apply to multi-step work (sweeps, migrations, runs of similar edits) and to how you stack commits and PRs. |
| `principle-subtract-before-you-add` | Apply when sequencing an addition, refactor, or rewrite. |
| `principle-test-behavior-not-implementation` | Apply when you write, change, or keep a test. |
| `principle-type-system-discipline` | Apply when designing types, reviewing a function signature, or writing code in any statically-typed language. |
| `pstack-babysit-pr` | Use when asked to babysit or monitor an existing PR or stack, get it merge-ready, check PR status, or address review bot comments. |
| `reflect` | Delegate three parallel reviewers over the active thread, surface learnings, and route each to a concrete edit on an existing skill. |
| `setup-p3` | Configure which models p3-stack uses per role and at what reasoning budget. |
| `show-me-your-work` | Keep a reviewable decision trail for long-running or unattended work: a TSV log with one row per decision (what, why, evidence, result). |
| `swarm` | Fan out N parallel workers, drain them, and return one report. |
| `tdd` | Use only when the user explicitly asks for TDD, a failing test, or a regression test, OR when the bug has an obvious cheap local test target. |
| `technical-writing` | Layered technical-writing standard: Diátaxis structure, Google developer style sentences, STE instruction rules, Global English syntax. |
| `typescript-best-practices` | TypeScript best practices. |
| `unslop` | Cut AI tells from any writing. |
| `upload-file` | Use when a user asks to upload, publish, share, preview, or host a generated or existing file so another person, tool, or agent can open it by URL. |
| `why` | Use for 'why does X work this way', 'why we picked Y', design rationale, regressions, postmortems, or data-backed thresholds. |

All entries except `upload-file` belong to the `pstack` profile. `upload-file` is an existing repository utility retained in `current` for file sharing.

Invoke `$p3-mode` in Codex or `/p3-mode` in Claude Code to use the P3 entrypoint. Its playbooks and worker briefs are bundled. The core workflow companions and all 24 principles are included. Partial installations can use the fallbacks in Local integration. Model roles in `p3-models.md` are honored when present; `setup-p3` is not required.

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


## Set up P3 on a machine

The repeatable setup installs the default profile for Codex and Claude Code, links the P3 profile into `~/.agents/skills`, and writes `~/.agents/p3-models.md`. It preserves unrelated skills. Run it separately on Linux and macOS with model IDs validated on that host.

1. Obtain the target host's `orchestrator_capabilities` result and save the structured JSON as `/tmp/p3-catalog.json`. In an agent session, invoke `$setup-p3` in Codex or `/setup-p3` in Claude Code to discover models and configure roles.
2. Select `gpt-6.1-sol` for coding and judgment, and `claude-opus-5-5` for review, using the provider instance IDs from that host. These are the two models selected for this collection.
3. Run the setup command from this checkout:

```sh
./scripts/setup-p3.sh \
  --catalog /tmp/p3-catalog.json \
  --coding <codex-provider>/gpt-6.1-sol \
  --judgment <codex-provider>/gpt-6.1-sol \
  --reviewer <claude-provider>/claude-opus-5-5 \
  --budget medium
```

`medium` means `high` reasoning. The helper uses the highest supported effort within that budget. Models without a reasoning option retain their provider behavior. Panels have two members by default. Provider and model selections live in the generated machine configuration, rather than in this repository.

`--check` prints the validated model configuration without changing files. An existing differing model configuration needs `--replace` after review. Project `p3-models.md` overrides the global file. Re-run setup to update a host. Existing `.agents/skills` collisions stop setup for review before installation; unrelated entries are retained.

The standalone configuration helper is `skills/active/setup-p3/scripts/configure.py`. It can update model roles without reinstalling skills. Its defaults, budget mapping, and role groups are the setup policy checked into this repository.

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
| [P3 Stack](https://github.com/uzairansaruzi/p3-stack) | `arena`, `how`, `why`, `interrogate`, `reflect`, `correct`, `p3-mode`, and `pstack-babysit-pr` |
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

`reflect` and `correct` come from [P3 Stack](https://github.com/uzairansaruzi/p3-stack/tree/09909ebb5c0125e27fad3e57d96b81e832696d69), commit `09909ebb5c0125e27fad3e57d96b81e832696d69`. Their manual invocation policy is preserved for both agents. The selected-set adaptation lets reflection run without `setup-p3`, `p3-models.md`, or the `p3-mode` authoring playbook. It uses live model discovery and the available skill-authoring workflow, scopes transcript reads to the requested session, and keeps external backlog filing within the user's authorization.

`pstack-babysit-pr` was initially adapted from the [pstack Babysit playbook](https://github.com/cursor/plugins/blob/99743e9c151c8537cbbf1f98bb38f34ef3368453/pstack/skills/poteto-mode/playbooks/babysit.md) and its review-triage rubric at commit `99743e9c151c8537cbbf1f98bb38f34ef3368453`. It now follows the [P3 Babysit playbook](https://github.com/uzairansaruzi/p3-stack/blob/09909ebb5c0125e27fad3e57d96b81e832696d69/skills/p3-mode/playbooks/babysit.md) and its rubric, reviewed at commit `09909ebb5c0125e27fad3e57d96b81e832696d69`. Its existing name is preserved. It supports one-pass status, review-only work, background monitoring, and driving a PR or stack to merge-ready. Stack work proceeds from the lowest unmerged PR upward. Babysitting leaves rebases to the branch owner and does not authorize merging.

In T3, the adapted skill uses `watch_pull_request`, yields while waiting, and stops its watches before handing work back. Outside T3, it uses available host monitoring. It does not require Cursor's `/loop`, the upstream watcher executable, or the rest of `poteto-mode`. Use it with requests such as "babysit this PR", "check on PR X", or "address the review comments". It starts when requested, not merely when a PR opens.

`how`, `why`, `interrogate`, and `arena` now follow P3, reviewed at commit `09909ebb5c0125e27fad3e57d96b81e832696d69`. Their prompts preserve P3's self-contained briefs and read-only research boundaries. Local adaptations use the current harness and live model catalog, honor configured `p3-models.md` roles when present, and work without installing `setup-p3` or the full P3 plugin. Separate child checkouts use `delegate_task` isolation rather than top-level conversations. Multi-model review defaults to two available models. Interrogate remains explicitly invoked in Codex and Claude Code and returns a verdict without applying fixes. Other additions retain automatic discovery for their stated tasks. Unslop also remains automatic.

The archived Matt Pocock TDD skill lives in `skills/archived/matt-pocock-tdd/` to distinguish it from the active pstack `tdd` skill. Its original files are unchanged.

For a complete feature workflow, ask the agent to implement and verify the change, run interrogate and fix confirmed findings, then open the PR and babysit CI and reviews. These steps run together only when requested; they do not imply permission to merge.

`p3-mode` and its 23 playbooks come from P3 Stack commit `09909ebb5c0125e27fad3e57d96b81e832696d69`. The import preserves explicit invocation in Codex and Claude Code, bundles the worker and comment-review briefs, and includes the upstream license. Local adaptations resolve resources from the installed skill, provide fallbacks for unselected companions, keep model setup optional, preserve task authorization, and use child-task worktree isolation for delegation. The entrypoint does not require the target project to vendor the upstream plugin.

The core P3 expansion adds `architect`, `swarm`, `figure-it-out`, `show-me-your-work`, `benchmark-checklist`, `setup-p3`, `no-comments`, and the 17 previously missing principle skills from P3 Stack commit `09909ebb5c0125e27fad3e57d96b81e832696d69`. The portable setup supports Linux and macOS, applies project then global model roles, and keeps the medium/high budget reproducible without committing account-specific configuration.
