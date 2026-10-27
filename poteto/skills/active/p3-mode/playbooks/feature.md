### Feature

**You own the design. Plan, review, verify.** Delegate implementation. Stay in the lead.

1. `how` over the affected subsystem.
2. `architect` for parallel design exploration.
3. Write the throughput checkpoint as four todo items. A dimension that genuinely does not apply (single file, no fan-out) keeps its item with `n/a: <reason>` rather than being dropped:
   - **Blocking first steps.** Gates run before fan-out.
   - **Independent workstreams.** Disjoint files, services, or layers parallelize. Shared writes serialize.
   - **Shared mutable state.** Default to splitting the target (the **separate-before-serializing-shared-state** principle skill). Serialize only for real invariants.
   - **Smallest safe decomposition.** If one worker is best, name why.
4. Delegate code-writing using the host and model fallbacks under Local integration. In T3, use `delegate_task` (`mode: "async"`, a self-contained brief drained with `task_status`) using the optional `feature, refactoring` role from `p3-models.md`, resolved through `orchestrator_capabilities`, with a specific scope (file paths, named data shape and its organizing structure per **principle-model-the-domain**, a state machine over scattered booleans, a table/registry over branching, a typed model over repeated shape assumptions, chosen before the delegate writes logic, and success criteria). When the implementation admits multiple valid shapes (error handling, abstraction layer, test structure), delegate via the **arena** skill instead so the runners surface the alternatives and the cross-judge guards the pick. Keep implementation and review separate when delegation is available. A delegate forbidden to spawn owns the diff directly and reports what review was possible. Comments per **Comments**. Surgical edits, re-ground against the source for upstream-derived files. Port shared-primitive improvements to all consumers and verify each. Create commits when the requested delivery includes them.
5. Verify on the matching surface. "Inconclusive" or wrong-surface is not a pass. Flag it.
6. Verify each small unit before the next. When delivering commits or a PR, organize small, ordered commits and stack follow-ups as needed. Preserve unrelated work when preparing the branch.
7. If the design is contested, `interrogate` before shipping.
8. Run **Opening a PR** (`playbooks/opening-a-pr.md`) when PR delivery is authorized. For a local implementation, report the validated diff.

Code-coupled work (one feature, one migration) goes to a single owner with the checkpoint inline. That owner fans out internally after the blocking phase. Parent-level fan-out is for slices that produce independent artifacts (audits, cross-subsystem investigations, competing experiments). Rewrite the checkpoint at phase boundaries. Spawn a fresh owner rather than chaining interrupts.

**Reply:** what you built, what you chose and why, the throughput checkpoint, open decisions. Tables for design alternatives.
