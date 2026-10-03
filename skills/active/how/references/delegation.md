# Delegation in T3, Codex, and Claude Code

Use the tools exposed by the current harness. Never assume Cursor's Task tool, model slugs, or configuration files exist.

In T3, call `orchestrator_capabilities` to discover enabled providers, their exact model IDs, supported options, and whether they can run child tasks. Prefer native subagents for same-provider work when they support the chosen model. For other models or providers, use `delegate_task` with `target.providerInstanceId`, `target.model`, `mode: async`, and a stable `clientRequestId`. Keep each returned `taskId`. Use completion notifications or `task_status` for outstanding tasks; never launch a duplicate because a wait expired. Do not use top-level thread creation for reviewers or investigators.

For independent reviews or candidate comparisons, default to two distinct models, preferably from different provider families. Respect the user's model choices and budget. Discover IDs at runtime rather than hard-coding them. If only one model is callable, use independent reviewers on it and disclose the reduced diversity. A third reviewer is optional for sensitive changes or when requested. Researchers and explainers can inherit the parent model unless the user specifies otherwise.

Outside T3, use the native delegation tools and their supported model catalog. If no delegation exists, perform one inline pass and clearly state that independent reviews or parallel exploration were unavailable. Never fabricate reviewer results or install another harness to complete the skill.

Give every child the complete task, intent, required reference text, scope, and output format. Children do not necessarily inherit parent context. Researchers, reviewers, and judges must not edit files, stage changes, commit, push, send messages, or mutate external applications. Pass that constraint in their prompts even when the harness has no read-only flag. Read-only evidence queries are allowed through available connectors.

Candidate writers may write only their assigned scratch output directory. T3 child tasks inherit the current checkout; a prompt mentioning a worktree does not change that binding. Use separate scratch directories for proposals. For this skill, do not create new top-level conversations or let competing candidates modify the shared checkout.

Report unavailable providers and failed reviewers honestly. Continue with the returned evidence when useful, without treating an incomplete panel as a complete review. Skill invocation authorizes its research or review workflow, not fixes, publication, merging, or unrelated PRs.
