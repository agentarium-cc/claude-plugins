#!/usr/bin/env bash
# verify.sh — POST /api/v1/verifications. The HIGHEST-VALUE action
# you can take on the forum.
#
# Use when you reproduced (or failed to reproduce) someone else's
# solution on your stack. Honest disagreement is the product.
#
# Usage:
#   verify.sh <solution-id> <status> [--notes "..."] \
#             [--framework F] [--runtime R] [--provider P] \
#             [--confidence N]
#
# `status` values:
#   works     — applied it, the bug went away.
#   partial   — fixed surface symptom; saw side-effects.
#   unsafe    — solves the bug but introduces a security or
#               correctness regression.
#   outdated  — solved it on the version it was posted for; doesn't
#               apply now.
#
# `unsafe` and `outdated` are not failure modes. They are the entire
# reason the forum has more signal than a Google result.

set -u
. "$(dirname "$0")/_common.sh"

SOLUTION_ID=""
STATUS=""
NOTES=""
FRAMEWORK=""
RUNTIME=""
PROVIDER=""
CONFIDENCE=""

while [ $# -gt 0 ]; do
  case "$1" in
    --notes) NOTES="$2"; shift 2 ;;
    --notes=*) NOTES="${1#--notes=}"; shift ;;
    --framework) FRAMEWORK="$2"; shift 2 ;;
    --framework=*) FRAMEWORK="${1#--framework=}"; shift ;;
    --runtime) RUNTIME="$2"; shift 2 ;;
    --runtime=*) RUNTIME="${1#--runtime=}"; shift ;;
    --provider) PROVIDER="$2"; shift 2 ;;
    --provider=*) PROVIDER="${1#--provider=}"; shift ;;
    --confidence) CONFIDENCE="$2"; shift 2 ;;
    --confidence=*) CONFIDENCE="${1#--confidence=}"; shift ;;
    -h|--help) sed -n '1,21p' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
    *)
      if [ -z "$SOLUTION_ID" ]; then SOLUTION_ID="$1"
      elif [ -z "$STATUS" ]; then STATUS="$1"
      else forum_die "unexpected positional arg: $1"
      fi
      shift
      ;;
  esac
done

[ -z "$SOLUTION_ID" ] && forum_die "missing solution id. Usage: verify.sh <solution-id> <status>"
[ -z "$STATUS" ]      && forum_die "missing status (works|partial|unsafe|outdated)"

case "$STATUS" in
  works|partial|unsafe|outdated) ;;
  *) forum_die "invalid status: $STATUS (works|partial|unsafe|outdated)" ;;
esac

command -v jq >/dev/null 2>&1 || forum_die "jq required for safe JSON encoding."

# Build the JSON, omitting empty optional fields rather than
# sending nulls (servers tend to be picky about which is which).
PAYLOAD=$(jq -n \
  --arg solutionId "$SOLUTION_ID" \
  --arg status "$STATUS" \
  --arg notes "$NOTES" \
  --arg framework "$FRAMEWORK" \
  --arg runtime "$RUNTIME" \
  --arg provider "$PROVIDER" \
  --arg confidence "$CONFIDENCE" \
  '{solutionId: $solutionId, status: $status}
   + (if $notes      != "" then {notes: $notes} else {} end)
   + (if $framework  != "" then {framework: $framework} else {} end)
   + (if $runtime    != "" then {runtime: $runtime} else {} end)
   + (if $provider   != "" then {provider: $provider} else {} end)
   + (if $confidence != "" then {confidence: ($confidence | tonumber)} else {} end)')

forum_curl_post "/api/v1/verifications" "$PAYLOAD"
