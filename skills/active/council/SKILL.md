---
name: council
description: Trigger this if the user says 'council'.
---

# Council

Before an audit, address outstanding PR comments, fix known issues, and run
relevant checks. Give council the updated implementation; do not defer known
fixes until reviews return. If the user wants to discard the implementation
and explore new ideas, skip fixes to code being replaced.

Bring in delegates to help with the user's request, usually for review or
feedback. Use the following members and effort settings unless the user
specifies different ones:

- Anthropic Claude Opus 5.5 (`claude-opus-5-5`), effort `high`.
- OpenAI GPT-6.2 Sol (`gpt-6.2-sol`), reasoning effort `high`.
- OpenAI GPT-6.2 Astra (`gpt-6.2-astra`), reasoning effort `high`.
- Include Gemini 4 Neon (`gemini-4-neon`) automatically whenever Antigravity
  can run it as a delegate. Check local `orchestrator_capabilities` first and
  use the current machine's resolved Antigravity provider instance. If local
  Antigravity cannot run it, use `t3_environment_links` to find reachable
  linked environments and check their provider catalogs. Pass the chosen
  remote `environmentId` and Antigravity provider instance to `delegate_task`.
  Start at most one Neon delegate. If no eligible environment can run Neon,
  run the other members and report why Neon could not run. Independently verify
  Neon's findings before acting on them.

In T3 Code, use `orchestrator_capabilities` to resolve each model to an enabled
provider instance that can run child tasks. Do not hardcode account-specific
provider instance IDs. Pass each member's specified effort through
`target.options`, using the option advertised by that provider, such as
`effort` or `reasoningEffort`.
Then use `delegate_task` to start one delegate per model in parallel.
Elsewhere, use the harness's subagent tools. Report any unavailable member or
required effort. Use the requested model IDs without substitutions.

Give each delegate the request and relevant context. For review or feedback,
keep their work read-only. Collect their responses and summarize the useful
findings, disagreements, and recommended next steps.

For a code review, ask each delegate for a score out of 10.
Count each full review pass as one round.
A fresh review after fixes starts a new round.

If the work ends in a pull request, put the results in the PR description.
Put this section before the model and harness line at the end:

```markdown
## Council review

Rounds: 2

| Delegate | Round 1 | Round 2 |
| --- | --- | --- |
| Claude Opus 5.5 | 7/10 | 9/10 |
| GPT-6.2 Sol | 8/10 | 10/10 |
| GPT-6.2 Astra | 7/10 | 9/10 |
| Gemini 4 Neon | 7/10 | 9/10 |
```

If a delegate gives no score, write `no score`. Do not invent one.
If the PR is open, edit the description. Do not post a comment for this.
If there is no PR, put the same results in the final reply only.

If you agree with their recommendations, make the changes and request a fresh
review after. Continue this process until all delegates are satisfied with the
outcome.

Do not let repeated reviews result in scope creep. It is your job to fight to
keep scope limited.
