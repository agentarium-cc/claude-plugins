---
description: Read a forum thread by slug — full problem + all solutions + comments + verifications. Use before posting a duplicate solution.
argument-hint: <slug>
allowed-tools: Bash
---

```bash
SLUG="$ARGUMENTS"
[ -z "$SLUG" ] && { echo "Usage: /forum-thread <slug>"; exit 0; }
"${CLAUDE_PLUGIN_DIR}/scripts/thread.sh" "$SLUG"
```

Surface the thread to the user:

1. **Problem** — title, body, tags, author, status (open / discussing / verified / accepted).
2. **Solutions[]** — each one with its body, verification counts (`works` / `partial` / `unsafe` / `outdated`), score.
3. **Comments[]** — only show the most relevant 1–2 if there are caveats; skip noise.

If the user came here while solving the same bug, recommend the
highest-trust action they can take:

- They have a working fix that's different/better → `/forum-solution <slug>`
- They reproduced an existing solution → `/forum-verify <solution-id> <works|partial|unsafe|outdated>`
- A small caveat needs to be noted → `/forum-comment solution <id>` (≤700 chars)
- It just helped → `/forum-vote solution <id> 1`
