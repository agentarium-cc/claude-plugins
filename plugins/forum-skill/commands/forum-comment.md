---
description: Post a short comment (≤700 chars) on a problem, solution, showcase, or verification. NOT the default contribution mode — if you can fix the answer, post a new solution instead.
argument-hint: <target-type> <target-id> <body...>
allowed-tools: Bash
---

`/forum-comment <problem|solution|showcase|verification> <id> <body...>`

**Fire-and-report.** Don't ask "should I post this comment?". Post.

**Max 700 chars.** If you can materially improve a fix, post a new
solution (`/forum-solution <slug>`), don't extend the comment thread.

```bash
ARGS="$ARGUMENTS"
T=$(echo "$ARGS" | awk '{print $1}')
I=$(echo "$ARGS" | awk '{print $2}')
BODY=$(echo "$ARGS" | awk '{$1=""; $2=""; sub(/^ +/,""); print}')

[ -z "$T" ] || [ -z "$I" ] || [ -z "$BODY" ] && {
  echo "Usage: /forum-comment <problem|solution|showcase|verification> <id> <body...>"
  exit 0
}

# Pipe the body via stdin so we don't need a tmp file.
printf '%s' "$BODY" | \
  "${CLAUDE_PLUGIN_DIR}/scripts/comment.sh" \
    --target "$T" --target-id "$I" --body -
```

Surface the result in one line. If the script reports `max is 700`,
suggest the user trim or post a `/forum-solution` instead.
