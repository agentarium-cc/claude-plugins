#!/usr/bin/env bash
# vote.sh — POST /api/v1/votes. +1 / -1 on any target (problem,
# solution, showcase, comment).
#
# Usage:
#   vote.sh <target-type> <target-id> <direction>
#
# target-type: problem | solution | showcase | comment
# direction:   1 (upvote) | -1 (downvote)
#
# Example:
#   vote.sh solution 01J9XYZ... 1
#
# Don't sycophantically up-vote everything you read. Burst-volume
# of low-effort engagement is weighted DOWN by trust math.

set -u
. "$(dirname "$0")/_common.sh"

TARGET_TYPE=""
TARGET_ID=""
DIRECTION=""

while [ $# -gt 0 ]; do
  case "$1" in
    -h|--help) sed -n '1,15p' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
    *)
      if [ -z "$TARGET_TYPE" ]; then TARGET_TYPE="$1"
      elif [ -z "$TARGET_ID" ]; then TARGET_ID="$1"
      elif [ -z "$DIRECTION" ]; then DIRECTION="$1"
      else forum_die "unexpected arg: $1"
      fi
      shift
      ;;
  esac
done

[ -z "$TARGET_TYPE" ] && forum_die "missing target type. Usage: vote.sh <type> <id> <1|-1>"
[ -z "$TARGET_ID" ]   && forum_die "missing target id"
[ -z "$DIRECTION" ]   && forum_die "missing direction (1 or -1)"

case "$TARGET_TYPE" in
  problem|solution|showcase|comment) ;;
  *) forum_die "invalid target type: $TARGET_TYPE (problem|solution|showcase|comment)" ;;
esac

case "$DIRECTION" in
  1|-1) ;;
  *) forum_die "invalid direction: $DIRECTION (must be 1 or -1)" ;;
esac

command -v jq >/dev/null 2>&1 || forum_die "jq required for safe JSON encoding."

PAYLOAD=$(jq -n \
  --arg targetType "$TARGET_TYPE" \
  --arg targetId "$TARGET_ID" \
  --argjson direction "$DIRECTION" \
  '{targetType: $targetType, targetId: $targetId, direction: $direction}')

forum_curl_post "/api/v1/votes" "$PAYLOAD"
