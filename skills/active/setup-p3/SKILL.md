---
name: setup-p3
description: Configure which models p3-stack uses per role and at what reasoning budget. Detects your available models and writes p3-models.md, which overrides the skill defaults. Use for /setup-p3, "configure p3 models", "p3 budget", or changing p3-stack's model choices.
disable-model-invocation: true
license: MIT
metadata:
  source: https://github.com/uzairansaruzi/p3-stack/tree/09909ebb5c0125e27fad3e57d96b81e832696d69/skills/setup-p3
  upstream_commit: 09909ebb5c0125e27fad3e57d96b81e832696d69
---

# Setup P3

Configure P3's models and reasoning budget for the current host. Read the current configuration before changing it. Reuse the user's stated budget and scope without asking again.

## Choose the scope and budget

Use project `p3-models.md` for project-specific choices, or `~/.agents/p3-models.md` for machine-wide setup. Project configuration takes precedence. For a request to set up a machine, use the global file.

Budgets map to reasoning effort as follows: `small` uses `medium`, `medium` uses `high`, `large` uses `xhigh`, and `unlimited` uses the highest advertised effort. The repository default is `medium`. If the user has not chosen a budget, state that default and allow them to change it. Existing explicit model choices take precedence over suggested defaults.

## Discover and select models

Call `orchestrator_capabilities` in the target host's session. Save its structured result to a temporary JSON file. Use its exact provider instance IDs, model IDs, and reasoning options. Do not copy one machine's account IDs to another without validating them there.

When configuring another host without a running agent session, its installed T3 provider configuration and current model manifest can establish available IDs. Validate reasoning capabilities with the installed provider binary. Record this catalog source honestly; do not describe it as a live tool response. If availability cannot be established, install the skills and report model configuration as pending.

Choose a strong coding model for code, exploration, and swarm roles. Choose a capable judgment model for design and synthesis. Prefer an independent provider for the review panel when available. Default to two panel members. Explain the chosen mapping and any reduced model diversity.

## Write and verify

Use [scripts/configure.py](scripts/configure.py). Paths below are relative to this installed skill:

```sh
python3 <setup-p3-dir>/scripts/configure.py \
  --catalog /tmp/p3-catalog.json \
  --coding <provider/model> \
  --judgment <provider/model> \
  --reviewer <provider/model> \
  --budget medium
```

The helper validates selections and efforts, writes all roles atomically, and leaves an identical configuration unchanged. `--check` validates and prints without writing. A differing existing file requires review and `--replace`; use it when the user's request already authorizes the configuration update. `--output <project>/p3-models.md` selects project scope.

Read the actual file after writing. Before every delegation, resolve its entries against that session's live catalog and apply each entry's effort through the advertised `reasoningEffort` or `effort` option. An unavailable entry needs a stated fallback or a configuration update. Never silently ignore it.

Report the configuration path, budget and effective reasoning, role mapping, and any host still pending. Skill discovery refreshes on the next turn; a new session can be used if the host caches it.
