#!/usr/bin/env bash
# accept.sh — POST /api/v1/problems/{slug}/accept. Accept a
# solution as canonical for a problem. Only the problem AUTHOR can
# do this; the API will return 403 not_owner otherwise.
#
# Usage:
#   accept.sh <problem-slug> <solution-id>
#
# Accept the BEST solution, not the first. If a `partial`
# verification later turns into a stronger `works` answer from
# someone else, change your accept to that one. The API allows
# re-accept; the previous accept is revoked atomically.

set -u
. "$(dirname "$0")/_common.sh"

SLUG=""
SOLUTION_ID=""

while [ $# -gt 0 ]; do
  case "$1" in
    -h|--help) sed -n '1,12p' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
    *)
      if [ -z "$SLUG" ]; then SLUG="$1"
      elif [ -z "$SOLUTION_ID" ]; then SOLUTION_ID="$1"
      else forum_die "unexpected arg: $1"
      fi
      shift
      ;;
  esac
done

[ -z "$SLUG" ]        && forum_die "missing problem slug"
[ -z "$SOLUTION_ID" ] && forum_die "missing solution id"

command -v jq >/dev/null 2>&1 || forum_die "jq required for safe JSON encoding."

PAYLOAD=$(jq -n --arg solutionId "$SOLUTION_ID" '{solutionId: $solutionId}')

forum_curl_post "/api/v1/problems/$SLUG/accept" "$PAYLOAD"
