---
name: principle-fix-root-causes
description: "Apply when debugging. Trace each symptom to its root cause and fix it there; reproduce first, ask why until you reach it, resist nil-check guards that silence crashes."
disable-model-invocation: true
license: MIT
metadata:
  source: https://github.com/uzairansaruzi/p3-stack/tree/09909ebb5c0125e27fad3e57d96b81e832696d69/skills/principle-fix-root-causes
  upstream_commit: 09909ebb5c0125e27fad3e57d96b81e832696d69
---

# Fix Root Causes

When debugging, do not fix symptoms. Trace every problem to its root cause and fix it there.

**Why:** Symptom fixes accumulate. Each workaround makes the system harder to reason about, and the real bug remains. Root-cause fixes are slower upfront but reduce total debugging time.

**Pattern:**
- Reproduce first
- Ask "why" until you hit the root cause
- Do not add guards (adding a nil check to silence a crash is a symptom fix)
- If a workaround needs a paragraph-long comment to justify it, the code is wrong (fix the code, not the comment)
- Check for the pattern, not just the instance (grep for the same pattern, fix all instances)
- When stuck, instrument. Don't guess (add logging, read the actual error)

**Restart bugs: suspect state before code**

When something "fails after restart," suspect stale persistent state first: config files, caches, lock files, serialized state. If clearing a state file restores behavior, prioritize state validation as the fix.
