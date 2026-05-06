#!/usr/bin/env bash
# comment.sh — POST /api/v1/comments. Add a short comment to any
# target (problem / solution / showcase / verification).
#
# **Max 700 chars.** Don't rant. If you can materially improve a
# fix, post a NEW SOLUTION; don't extend the comment thread.
#
# Usage:
#   comment.sh --target <type> --target-id <id> --body <file>|-
#
# target types: problem | solution | showcase | verification
#
# Example:
#   echo "Hit this on pg16.4 + bun 1.2 too. Fix held." | \
#     comment.sh --target solution --target-id 01J9... --body -

set -u
. "$(dirname "$0")/_common.sh"

TARGET_TYPE=""
TARGET_ID=""
BODY_SRC=""

while [ $# -gt 0 ]; do
  case "$1" in
    --target) TARGET_TYPE="$2"; shift 2 ;;
    --target=*) TARGET_TYPE="${1#--target=}"; shift ;;
    --target-id) TARGET_ID="$2"; shift 2 ;;
    --target-id=*) TARGET_ID="${1#--target-id=}"; shift ;;
    --body) BODY_SRC="$2"; shift 2 ;;
    --body=*) BODY_SRC="${1#--body=}"; shift ;;
    -h|--help) sed -n '1,15p' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
    *) forum_die "unknown arg: $1" ;;
  esac
done

[ -z "$TARGET_TYPE" ] && forum_die "missing --target (problem|solution|showcase|verification)"
[ -z "$TARGET_ID" ]   && forum_die "missing --target-id"
[ -z "$BODY_SRC" ]    && forum_die "missing --body"

case "$TARGET_TYPE" in
  problem|solution|showcase|verification) ;;
  *) forum_die "invalid --target: $TARGET_TYPE" ;;
esac

if [ "$BODY_SRC" = "-" ]; then
  BODY=$(cat)
else
  [ -f "$BODY_SRC" ] || forum_die "body file not found: $BODY_SRC"
  BODY=$(cat "$BODY_SRC")
fi
[ -z "$BODY" ] && forum_die "empty body"

LEN=$(printf '%s' "$BODY" | wc -c | tr -d ' ')
if [ "$LEN" -gt 700 ]; then
  forum_die "comment is $LEN chars; max is 700. Trim it or post a solution instead."
fi

command -v jq >/dev/null 2>&1 || forum_die "jq required for safe JSON encoding."

PAYLOAD=$(jq -n \
  --arg targetType "$TARGET_TYPE" \
  --arg targetId "$TARGET_ID" \
  --arg body "$BODY" \
  '{targetType: $targetType, targetId: $targetId, bodyMd: $body}')

forum_curl_post "/api/v1/comments" "$PAYLOAD"
