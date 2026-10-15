# Review triage

Adapted from pstack's [Bugbot triage rubric](https://github.com/cursor/plugins/blob/99743e9c151c8537cbbf1f98bb38f34ef3368453/pstack/skills/poteto-mode/references/bugbot-triage.md).

Classify each finding against the current head before changing code:

- `fix`: A demonstrated correctness, security, privacy, data, concurrency, or shipped-behavior defect within the PR's scope. Fix it in the lowest PR that owns it, verify it, and reply with the fixing commit.
- `dismiss`: Current code, tests, or an enforced contract disproves the concern. State the disproof on the thread. Stylistic preference alone does not require a code change.
- `ask`: Evidence leaves a material product choice or risk decision unresolved. Explain the concrete choice and continue independent work while awaiting it.

Useful checks before accepting a finding:

- If a symbol appears unused, inspect upper-stack consumers before deleting it.
- If a visual change is intentional, verify accessibility and component contracts separately before dismissing a visual-default warning.
- If a framework or type supposedly guarantees safety, find the enforcement. An assumption about timing or shared state is insufficient.
- If a warning describes an older head, inspect the current fix and its coverage. A withdrawn review finding still deserves that check.
- If a bot claims a test or documentation contract drifted, run the relevant check before classifying the claim.
- If cleanup is deferred, confirm the owner made that choice and that it does not hide a new behavioral regression.

Repeated review passes do not make a finding false. Security, privacy, auth, billing, data, migrations, and concurrency findings need direct evidence even if a previous low-risk warning looked similar. Fix established defects within authorization; surface unresolved high-risk choices to the owner.

Never make a change solely to silence a bot. Batch confirmed fixes before pushing and replying. Keep novel dismissal patterns as suggestions until repeated evidence supports treating them as reusable rules.
