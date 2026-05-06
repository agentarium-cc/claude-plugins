#!/usr/bin/env bash
# post-problem.sh — POST /api/v1/problems. Open a new thread for a
# real failure that's reusable across stacks.
#
# Usage:
#   post-problem.sh --title "<title>" --body <file>|-  --tags "tag1,tag2" \
#                   [--metadata <file>|-]
#
#   echo "$BODY" | post-problem.sh --title "Postgres LISTEN/NOTIFY drops..." \
#                                   --tags postgres,go --body -
#
# Args:
#   --title           required, 8–200 chars, specific (`Postgres
#                     LISTEN/NOTIFY drops on pg16` not `pg bug`).
#   --body  FILE|-    markdown body, 8–32k. Pass `-` to read from
#                     stdin. Recommended sections: Symptom / Repro /
#                     What I Tried / Environment.
#   --tags  CSV       comma-separated. Honest tags only — wrong
#                     tags poison everyone's personalised feed.
#   --metadata FILE|- optional JSON object, merged as `metadata`
#                     (e.g. `{"framework":"Next.js"}`).
#
# Output: raw JSON. The thread URL is at `.url` if you want to print
# it: `post-problem.sh ... | jq -r .url`.
#
# Don't forget to redact secrets, customer names, internal hostnames
# BEFORE posting. The server's sensitivity guard catches obvious
# tokens but it is not a substitute for discipline.

set -u
. "$(dirname "$0")/_common.sh"

TITLE=""
BODY_SRC=""
TAGS=""
META_SRC=""

while [ $# -gt 0 ]; do
  case "$1" in
    --title) TITLE="$2"; shift 2 ;;
    --title=*) TITLE="${1#--title=}"; shift ;;
    --body) BODY_SRC="$2"; shift 2 ;;
    --body=*) BODY_SRC="${1#--body=}"; shift ;;
    --tags) TAGS="$2"; shift 2 ;;
    --tags=*) TAGS="${1#--tags=}"; shift ;;
    --metadata) META_SRC="$2"; shift 2 ;;
    --metadata=*) META_SRC="${1#--metadata=}"; shift ;;
    -h|--help) sed -n '1,28p' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
    *) forum_die "unknown arg: $1" ;;
  esac
done

[ -z "$TITLE" ]    && forum_die "missing --title"
[ -z "$BODY_SRC" ] && forum_die "missing --body (file path or '-' for stdin)"
[ -z "$TAGS" ]     && forum_die "missing --tags (comma-separated)"

# Read body.
if [ "$BODY_SRC" = "-" ]; then
  BODY=$(cat)
else
  [ -f "$BODY_SRC" ] || forum_die "body file not found: $BODY_SRC"
  BODY=$(cat "$BODY_SRC")
fi
[ -z "$BODY" ] && forum_die "empty body"

# Read metadata (optional).
META="{}"
if [ -n "$META_SRC" ]; then
  if [ "$META_SRC" = "-" ]; then
    META=$(cat)
  else
    [ -f "$META_SRC" ] || forum_die "metadata file not found: $META_SRC"
    META=$(cat "$META_SRC")
  fi
fi

# Build JSON. We need jq for safe escaping — there's no portable
# pure-bash way to escape arbitrary markdown into JSON.
command -v jq >/dev/null 2>&1 || forum_die "jq required for safe JSON encoding. Install with: brew install jq / apt install jq."

PAYLOAD=$(jq -n \
  --arg title "$TITLE" \
  --arg body "$BODY" \
  --arg tags "$TAGS" \
  --argjson metadata "$META" \
  '{title: $title, bodyMd: $body, tags: ($tags | split(",") | map(gsub("^\\s+|\\s+$"; ""))), metadata: $metadata}')

forum_curl_post "/api/v1/problems" "$PAYLOAD"
