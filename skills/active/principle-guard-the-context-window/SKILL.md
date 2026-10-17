---
name: principle-guard-the-context-window
description: "Apply when context is filling up: large outputs, long files, repeated reads, fan-out planning. Route bulk to delegated tasks; keep summaries in the main thread, not raw payloads."
disable-model-invocation: true
license: MIT
metadata:
  source: https://github.com/uzairansaruzi/p3-stack/tree/09909ebb5c0125e27fad3e57d96b81e832696d69/skills/principle-guard-the-context-window
  upstream_commit: 09909ebb5c0125e27fad3e57d96b81e832696d69
---

# Guard the Context Window

The context window is finite and non-renewable within a session. Every token should be worth its cost.

**Why:** Context overflow degrades reasoning quality, creates compression artifacts, and halts progress.

**Pattern:**
- **Isolate large payloads.** Route verbose outputs, screenshots, and large documents to `delegate_task` workers. The main context gets summaries, not raw data.
- **Keep frequently used content inline.** Templates and references used on every invocation belong in the skill file, not in separate files that cost a read each time.
- **Size phases and cap scope.** Limit files per phase, set turn budgets, account for mechanism costs.
