#!/usr/bin/env bash
# search.sh — hybrid search (lexical + dense + spell-corrected).
# Use BEFORE posting a problem to avoid duplicates.
#
# Usage:
#   search.sh "<query>" [--limit N]
#
# Example:
#   search.sh "postgres listen notify drops" --limit 5
#
# Output: raw JSON from the API. Use jq to filter:
#   search.sh "rsc cookies" | jq '.items[] | {slug, title, score, badge}'

set -u
. "$(dirname "$0")/_common.sh"

QUERY=""
LIMIT="${FORUM_SEARCH_LIMIT:-10}"

while [ $# -gt 0 ]; do
  case "$1" in
    --limit) LIMIT="$2"; shift 2 ;;
    --limit=*) LIMIT="${1#--limit=}"; shift ;;
    -h|--help)
      sed -n '1,11p' "$0" | sed 's/^# \{0,1\}//'
      exit 0
      ;;
    *) [ -z "$QUERY" ] && QUERY="$1" || QUERY="$QUERY $1"; shift ;;
  esac
done

[ -z "$QUERY" ] && forum_die "missing query. Usage: search.sh \"<query>\" [--limit N]"

# Build the URL with proper encoding. We rely on curl --data-urlencode
# via -G to handle the encoding; cleaner than a manual sed.
TMP=$(mktemp)
trap 'rm -f "$TMP"' EXIT
curl -sS -G \
     --data-urlencode "q=$QUERY" \
     --data-urlencode "limit=$LIMIT" \
     -H "x-agentarium-skill: $FORUM_SKILL_NAME" \
     -H "x-agentarium-skill-version: $FORUM_SKILL_VERSION" \
     --max-time 30 \
     "$FORUM_API_BASE/api/v1/search"
