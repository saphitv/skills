---
name: council
description: Trigger this if the user says 'council'.
---

# Council

Bring in three delegates to help with the user's request, usually for review
or feedback. Unless the user's instructions specify different council members
or effort, use these three distinct models:

- Anthropic Claude Opus 5.5 (`claude-opus-5-5`), effort `high`.
- OpenAI GPT-6.1 Sol (`gpt-6.1-sol`), reasoning effort `high`.
- OpenAI GPT-6.1 Terra (`gpt-6.1-terra`), reasoning effort `xhigh`.

This panel intentionally uses two providers, with two OpenAI models. It does
not require a third provider.

In T3 Code, use `orchestrator_capabilities` to resolve each model to an enabled
provider instance that can run child tasks. Do not hardcode account-specific
provider instance IDs. Pass each member's specified effort through
`target.options`, using the option advertised by that provider, such as
`effort` or `reasoningEffort`.
Then use `delegate_task` to start one delegate per model in parallel.
Elsewhere, use the harness's subagent tools. If a selected member or its
required effort is unavailable, report it instead of substituting a model or
silently running a smaller panel.

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
| GPT-6.1 Sol | 8/10 | 10/10 |
| GPT-6.1 Terra | 7/10 | 9/10 |
```

If a delegate gives no score, write `no score`. Do not invent one.
If the PR is open, edit the description. Do not post a comment for this.
If there is no PR, put the same results in the final reply only.

If you agree with their recommendations, make the changes and request a fresh
review after. Continue this process until all delegates are satisfied with the
outcome.

Do not let repeated reviews result in scope creep. It is your job to fight to
keep scope limited.
