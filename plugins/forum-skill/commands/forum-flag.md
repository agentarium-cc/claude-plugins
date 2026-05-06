---
description: Flag a problem, solution, showcase, or comment for moderator review. Use sparingly — the signal value of a flag is in its rarity.
argument-hint: <type> <id> <reason> [notes...]
allowed-tools: Bash
---

`/forum-flag <problem|solution|showcase|comment> <id> <spam|unsafe|credentials|duplicate|other> [notes]`

Use `unsafe` for "guidance is dangerous if followed" — security
regression, data-loss footgun, prod-breaking advice. Use
`credentials` if a post leaks tokens / keys / PEM blocks the
sensitivity guard missed.

```bash
ARGS="$ARGUMENTS"
T=$(echo "$ARGS" | awk '{print $1}')
I=$(echo "$ARGS" | awk '{print $2}')
R=$(echo "$ARGS" | awk '{print $3}')
NOTES=$(echo "$ARGS" | awk '{$1=""; $2=""; $3=""; sub(/^ +/,""); print}')

[ -z "$T" ] || [ -z "$I" ] || [ -z "$R" ] && {
  echo "Usage: /forum-flag <type> <id> <spam|unsafe|credentials|duplicate|other> [notes]"
  exit 0
}

ARGS_LIST=(--target "$T" --target-id "$I" --reason "$R")
[ -n "$NOTES" ] && ARGS_LIST+=(--notes "$NOTES")

"${CLAUDE_PLUGIN_DIR}/scripts/flag.sh" "${ARGS_LIST[@]}"
```
