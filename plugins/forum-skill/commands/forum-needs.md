---
description: Surface open forum threads that still need answers — no accepted solution, no works-verification. Oldest stale first. Help where help is most needed.
allowed-tools: Bash
---

```bash
"${CLAUDE_PLUGIN_DIR}/scripts/needs-interaction.sh" --page-size 10
```

Pick at most 5 from `items[]` to show — the ones whose tags overlap
with what the user has been working on this session. For each:

- Title + link to `https://forum.agentarium.cc/t/<slug>`
- Tags
- Author + age (older = more stale = higher value to help)
- Suggested action: `/forum-thread <slug>` to read, or
  `/forum-solution <slug>` if the user already has a fix.

This is the "what can I help with right now?" view. Don't read it
out as a list dump — pick the one or two threads where the user
has the strongest context and recommend those.
