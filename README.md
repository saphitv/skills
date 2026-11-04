# Agent skills

Personal skills for Codex and Claude Code. The current profile installs the nine skills from [Theo Browne's tstack](https://github.com/t3dotgg/tstack) and the locally maintained `upload-file` skill.

## Active skills

| Skill | Purpose |
| --- | --- |
| `full-send` | Complete, validate, review, file, monitor, and merge a PR. |
| `full-stop` | Prepare a PR for the user to merge. |
| `council` | Request reviews from Claude Opus 5.5, GPT-6.1 Sol, and GPT-6.1 Terra across two providers. |
| `sol-loop` | Repeat reviews with GPT Sol until agreement. |
| `file-pr` | File a concise PR focused on the problem. |
| `takeover` | Finish an existing PR, branch, or agent thread while preserving contributor credit. |
| `babysit-pr` | Monitor CI and reviews and address valid findings. |
| `modernize` | Rebase an old PR and assess whether it is still needed. |
| `leaving-pr-comments` | Format agent-authored GitHub comments. |
| `upload-file` | Upload a requested file with the existing `upload` command. |

[`profiles/current.txt`](profiles/current.txt) selects all ten skills. [`profiles/tstack.txt`](profiles/tstack.txt) selects the nine upstream skills. [`profiles/default`](profiles/default) selects `current`.

Council defaults to Claude Opus 5.5 at `high`, GPT-6.1 Sol at `high`, and GPT-6.1 Terra at `xhigh`. It intentionally uses two OpenAI reviewers and needs no third provider. Explicitly named council members or effort settings override these defaults. Unavailable members are reported rather than silently replaced. Provider account IDs are resolved from the live catalog on each machine.

## Install

Run the installer from a checkout of this repository:

```sh
./scripts/install.sh status
./scripts/install.sh
./scripts/install.sh status
```

It installs into `$CODEX_HOME/skills` and `$CLAUDE_CONFIG_DIR/skills`, defaulting to `~/.codex/skills` and `~/.claude/skills`. Existing copies of selected skills are replaced. Use `--profile tstack` for the upstream skills alone, `--profile all` for every active skill, or pass explicit skill names.

The installer preserves unrelated skills. After reviewing status, remove stale copies previously managed by this installer with:

```sh
./scripts/install.sh prune --yes
```

Unmanaged skills require separate review and removal. Keep backups outside every agent's skill discovery directory. When `~/.agents/skills` contains links to the installed Codex skills, update those links when changing the selected collection.

The machine-specific `.agent-skills.lock.json` records destinations, file hashes, executable bits, and source revisions. It remains untracked. New skills are available on the next turn.

## Security audit trial

`security-audit-testing` is an experimental copy of [Cloudflare's security-audit skill](https://github.com/cloudflare/security-audit-skill), pinned to [`c1c8a8c1471069fb0e188eeaff69b8e8db6564a8`](https://github.com/cloudflare/security-audit-skill/commit/c1c8a8c1471069fb0e188eeaff69b8e8db6564a8). It retains the complete upstream workflow, references, schema, validators, and tests. Only the discovery name, description, provenance note, and UI metadata are adapted for the trial.

Install just the trial in Codex and Claude Code. These commands select the normal Codex home explicitly so install and removal use the same paths even in a T3 session with a symlinked `CODEX_HOME`. Substitute a custom home consistently if needed.

```sh
CODEX_HOME="$HOME/.codex" ./scripts/install.sh security-audit-testing
```

[`profiles/security-testing.txt`](profiles/security-testing.txt) selects the normal collection plus the trial. Use `CODEX_HOME="$HOME/.codex" ./scripts/install.sh --profile security-testing` to install that whole selection. The default remains `current`; a normal install does not add or reinstall the trial.

On the next turn, try `Use $security-audit-testing for a quick security audit of <repo or subsystem>`. Full audits require subagents, Node.js, and the upstream OS-enforced sandbox controls for target-code execution. Source review can proceed when execution is unavailable; the report must disclose the resulting validation gaps.

To remove the installed trial and return to the normal selection:

```sh
CODEX_HOME="$HOME/.codex" ./scripts/install.sh status --profile current
CODEX_HOME="$HOME/.codex" ./scripts/install.sh prune --profile current --yes
```

Prune removes installer-managed copies outside `current`, including this trial; it preserves unmanaged skills. Inspect status for any other stale managed entries before pruning. The repository copy stays available for reinstalling. Revert the trial's import commit as well if you want to discard it from the collection entirely.

Other sources checked on 2026-11-04:

- [Trail of Bits skills](https://github.com/trailofbits/skills) includes focused tools such as `differential-review`, `variant-analysis`, and `fp-check`. These are useful candidates for later trials, rather than a single replacement for Cloudflare's repository-wide workflow.
- [Sentry security-review](https://github.com/getsentry/skills/tree/main/skills/security-review) provides a focused file/diff review. Its current instructions include a blanket exclusion for authenticated code paths and unconditional pattern-based flags; review those rules before adopting it for access-control audits.

## Requirements

- An authenticated GitHub CLI, `gh`, for PR workflows.
- Python 3 for the upstream `babysit-pr/scripts/pr-wait` helper and the update checker.
- Access to the requested models for `council` and `sol-loop`. T3 Code supports these through `delegate_task`.
- The existing `upload` command and its machine-local configuration for `upload-file`. Credentials are not stored here.

## Update skills

[`upstreams.json`](upstreams.json) records one update source for each active skill. The nine tstack skills track `t3dotgg/tstack`; the optional security audit trial tracks `cloudflare/security-audit-skill`; `upload-file` is maintained locally.

1. Run `python3 scripts/check-upstreams.py` to find upstream changes.
2. Review every changed tracked path, including supporting scripts and the license. Preserve local adaptations recorded in the map.
3. Update the active skill files and advance `reviewed_commit` only after review. Keep the upstream MIT license in each imported skill.
4. Run `python3 scripts/check-upstreams.py --validate`, `./tests/install_test.sh`, and `python3 -B -m unittest discover -s tests -p '*_test.py'`.
5. Commit and push the change. On each machine, pull the repository, inspect installer status, install, and verify status again.

Installation profiles select skills; they do not define update sources. Add or remove map entries whenever skills enter or leave `skills/active/`.

## Previous collection

[`poteto/`](poteto/) preserves all 82 previous skill directories, including the former active, disabled, and archived collections. It also preserves their README, profiles, update map, installer tests, and P3 setup helper. The original `upload-file` is retained there as part of the snapshot and copied unchanged into the active collection.

The installer reads only `skills/active/` and never installs from `poteto/`. The old P3 profile and setup command are archived. Do not point an agent's skill directory at this repository or recursively install its archive.

## Credits

The nine tstack skills are by Theo Browne, under the [MIT license](skills/active/full-send/LICENSE). They were imported from commit `92e38e2cf677a84a142e8df296861c588542135c` and reviewed through `1085050f3baed1ac724caa4a8166145fb2ac88af`, with the license bundled in every skill. Local adaptations in `upstreams.json` configure council's three-model panel across two providers and make babysit-pr resolve review threads after their findings are fixed, checked, and pushed. The other imported instructions and supporting files are unchanged.

`upload-file` is the existing locally maintained utility. Historical author credits, licenses, and adaptation notes remain in `poteto/`.

`security-audit-testing` is by Cloudflare, Inc., under its bundled [MIT license](skills/active/security-audit-testing/LICENSE). Its source revision and trial adaptations are recorded in `upstreams.json`.
