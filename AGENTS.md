# Maintaining this skill collection

When asked to update skills, read the [update procedure](README.md#update-skills) and [upstream map](upstreams.json) first.

- Every active skill has one update source in `upstreams.json`: P3 Stack, original pstack, or local maintenance.
- Run `python3 scripts/check-upstreams.py` to find changes since each skill's reviewed commit. This command is read-only.
- Compare the recorded upstream revision with the new upstream revision, then integrate relevant changes into the local skill and its supporting files. Local differences alone do not mean a skill is outdated.
- Preserve the adaptations recorded in the map, original author credits, and licenses. Historical import sources in the README or skill metadata do not override the update map.
- Advance `reviewed_commit` only after reviewing every tracked path and recording any intentional omissions in `adaptations`.
- Add an upstream entry when activating a skill. Remove its entry when disabling or archiving it. Validate coverage with `python3 scripts/check-upstreams.py --validate`.

Keep installation profiles separate from update sources. An update request covers active repository skills; include disabled, archived, or separately supplied skills only when requested. Use installer status to distinguish upstream changes from missing or differing installed copies.
