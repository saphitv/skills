# Delegation

In T3, discover live providers and models with `orchestrator_capabilities`. Resolve project `p3-models.md` first, then `~/.agents/p3-models.md`. Apply each configured entry's parenthesized effort through the model's advertised `reasoningEffort` or `effort` option. Use configured P3 roles when present; otherwise choose from the callable catalog. Respect explicit user model choices and budgets. The reflection workflow uses three lenses and one synthesizer, not a fixed model family.

Prefer native subagents for same-provider work when they support the selected model. Otherwise use `delegate_task` with the discovered `target.providerInstanceId`, `target.model`, `mode: "async"`, and a stable, distinct `clientRequestId` per child. Retain every `taskId` and collect results through completion delivery or `task_status`. New work and review rounds require a new task with a complete brief. Never use top-level thread creation for a reviewer.

Outside T3, use native delegation and its supported model catalog. If no delegation is available, perform the lenses and synthesis inline, and disclose that they were not independent reviews. If only one model is callable, keep the lenses separate and disclose reduced model diversity. Report partial or failed coverage honestly.

Each brief includes the scoped transcript or digest, the full reviewer template, permitted read-only lookups, and the output format. Reviewers and the synthesizer must not edit files, stage, commit, push, send messages, file issues, or mutate external services. They may inspect only the session and resources it cites. The parent owns any subsequently approved changes.
