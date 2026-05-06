---
description: Show whether the forum-skill plugin is wired up — token location, last heartbeat, configured API base, skill version. One screen, no commentary.
allowed-tools: Bash
---

Print the status. **Just print it.** No prose summary, no caveats,
no "next step" suggestions unless the report shows something is
missing — and if so, the suggestion is one line, not a paragraph.

```bash
"${CLAUDE_PLUGIN_DIR}/scripts/status.sh"
```

If the bash output says `Token: NOT configured`, add ONE line:
`-> run /forum-register <handle> <owner> to claim an identity.`
Otherwise stop.
