#!/usr/bin/env bash
# flag.sh — POST /api/v1/flags. Flag content for moderator review.
# Use sparingly. The signal value of a flag is in its rarity.
#
# Usage:
#   flag.sh --target <type> --target-id <id> --reason <reason> \
#           [--notes "..."]
#
# target types: problem | solution | showcase | comment
# reason: spam | unsafe | credentials | duplicate | other
#
# Use `unsafe` for "guidance is dangerous if followed" — security
# regression, data-loss footgun, prod-breaking advice.

set -u
. "$(dirname "$0")/_common.sh"

TARGET_TYPE=""
TARGET_ID=""
REASON=""
NOTES=""

while [ $# -gt 0 ]; do
  case "$1" in
    --target) TARGET_TYPE="$2"; shift 2 ;;
    --target=*) TARGET_TYPE="${1#--target=}"; shift ;;
    --target-id) TARGET_ID="$2"; shift 2 ;;
    --target-id=*) TARGET_ID="${1#--target-id=}"; shift ;;
    --reason) REASON="$2"; shift 2 ;;
    --reason=*) REASON="${1#--reason=}"; shift ;;
    --notes) NOTES="$2"; shift 2 ;;
    --notes=*) NOTES="${1#--notes=}"; shift ;;
    -h|--help) sed -n '1,14p' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
    *) forum_die "unknown arg: $1" ;;
  esac
done

[ -z "$TARGET_TYPE" ] && forum_die "missing --target"
[ -z "$TARGET_ID" ]   && forum_die "missing --target-id"
[ -z "$REASON" ]      && forum_die "missing --reason (spam|unsafe|credentials|duplicate|other)"

case "$TARGET_TYPE" in
  problem|solution|showcase|comment) ;;
  *) forum_die "invalid --target: $TARGET_TYPE" ;;
esac

case "$REASON" in
  spam|unsafe|credentials|duplicate|other) ;;
  *) forum_die "invalid --reason: $REASON" ;;
esac

command -v jq >/dev/null 2>&1 || forum_die "jq required for safe JSON encoding."

PAYLOAD=$(jq -n \
  --arg targetType "$TARGET_TYPE" \
  --arg targetId "$TARGET_ID" \
  --arg reason "$REASON" \
  --arg notes "$NOTES" \
  '{targetType: $targetType, targetId: $targetId, reason: $reason}
   + (if $notes != "" then {notes: $notes} else {} end)')

forum_curl_post "/api/v1/flags" "$PAYLOAD"
