---
name: reflect
description: Delegate three parallel reviewers over the active thread, surface learnings, and route each to a concrete edit on an existing skill. Use when the user says reflect.
disable-model-invocation: true
license: MIT
metadata:
  source: https://github.com/uzairansaruzi/p3-stack/tree/09909ebb5c0125e27fad3e57d96b81e832696d69/skills/reflect
  upstream_commit: 09909ebb5c0125e27fad3e57d96b81e832696d69
---

# Reflect

Mine the current conversation for durable learnings, then route them into skill edits.

## When to invoke

Invoke when the user says "reflect" or "/reflect". Skip when the conversation is trivial, off-topic, or already covered by an existing skill the parent followed correctly. One-offs are not learnings.

## Process

### 1. Locate the active transcript

The transcript is the current T3 thread unless the user specifies another. Read its pages with `t3_thread_read`, recovering truncated items before citing them. Do not search across other threads. Outside T3, use the current conversation or a transcript the user identified; do not scan unrelated session logs.

Reviewers get only their brief, never the parent's context. Pass the thread id and tell them to read it with `t3_thread_read`, or write a tight digest of the session and pass that instead.

### 2. Delegate three reviewers in parallel

Read [references/delegation.md](references/delegation.md). Launch three independent reviewers asynchronously. Reviewers may make read-only context lookups for tickets, chat threads, and traces cited by the session, but cannot edit files or mutate external services.

Resolve models from the live catalog. Honor existing role lines in `p3-models.md` when present; without that file, use available models and prefer different families for independent lenses. Never hardcode a slug.

| Lens | Role line | Prompt template |
|---|---|---|
| Judgment | `reflect judgment, divergent, synthesizer` | [Judgment reviewer](references/judgment-reviewer.md) |
| Tooling | `reflect tooling` | [Tooling reviewer](references/tooling-reviewer.md) |
| Divergent | `reflect judgment, divergent, synthesizer` | [Divergent reviewer](references/divergent-reviewer.md) |

Fill each template with the scoped thread ID or session digest. Each brief must stand alone. Retain task IDs and collect every result without launching duplicate work when a wait expires.

### 3. Synthesize

Launch one read-only synthesizer, using the configured role if present. Its quality check includes spot-verifying citations. Fill [references/synthesizer.md](references/synthesizer.md) with each reviewer's full output. The synthesizer returns a structured Accepted / Rejected / Backlog list.

### 4. Structural enforcement check

Sanity-check the synthesizer's Accepted list. For any item that would be enforced more reliably by a lint rule, script, metadata flag, or runtime check, move it from Accepted to Backlog. Read [principle-encode-lessons-in-structure](../principle-encode-lessons-in-structure/SKILL.md). Such items may be candidates for a separately requested `correct` run.

### 5. Apply

Before applying any Accepted edit, present the synthesizer's full Accepted/Rejected/Backlog output to the user and wait for explicit approval. The user picks which subset to apply and may redirect routings. Skill changes affect every future agent in the org. Do not auto-apply.

Keep Backlog items in the report. File them in an external tracker only when the user has authorized that action. Reflection alone does not authorize repository fixes or external writes.

For each approved Accepted item, follow the Routing field exactly:

- Trivial existing-skill edit (a one-line bullet, a tightened sentence, a stale fact corrected): parent does directly.
- Substantive existing-skill edit or `tune description: <skill path>`: use the available skill-authoring workflow, such as `skill-creator`, and validate the approved change against a realistic request.
- `new skill: <kebab-name>`: use the available skill-authoring workflow only after approval. Do not require the uninstalled `p3-mode` authoring playbook.

If your environment ships a SKILL.md validator, run it on every touched skill before declaring done. Skip this step if it doesn't.

### 6. Summarize for the user

Short list, no preamble:

- Edits applied: `<skill path>`. What changed, one line each.
- New skills created: `<skill path>`. One line each (rare).
- Backlog: one line per proposed structural fix, with issue links only if filing was authorized and completed.
- Dropped: one line per rejected finding + reason from the synthesizer.
