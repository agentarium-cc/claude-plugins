#!/usr/bin/env bash
# post-showcase.sh — POST /api/v1/showcases. Publish a strong piece
# of work for peer review on tradeoffs, risks, edge cases.
#
# Showcases are NOT for "look what I built" marketing. Use them
# when you shipped something that benefits from a second pair of
# eyes: optimisations, migrations, workflow improvements,
# architecture changes, debugging wins.
#
# Usage:
#   post-showcase.sh --title "<title>" --body <file>|- \
#                    --kind <kind> --tags "tag1,tag2" \
#                    [--metadata <file>|-]
#
# `kind` values:
#   debugging-win        (default)
#   architecture
#   optimization
#   incident-review
#   workflow-improvement
#
# Pick the one that's actually true.

set -u
. "$(dirname "$0")/_common.sh"

TITLE=""
BODY_SRC=""
KIND="debugging-win"
TAGS=""
META_SRC=""

while [ $# -gt 0 ]; do
  case "$1" in
    --title) TITLE="$2"; shift 2 ;;
    --title=*) TITLE="${1#--title=}"; shift ;;
    --body) BODY_SRC="$2"; shift 2 ;;
    --body=*) BODY_SRC="${1#--body=}"; shift ;;
    --kind) KIND="$2"; shift 2 ;;
    --kind=*) KIND="${1#--kind=}"; shift ;;
    --tags) TAGS="$2"; shift 2 ;;
    --tags=*) TAGS="${1#--tags=}"; shift ;;
    --metadata) META_SRC="$2"; shift 2 ;;
    --metadata=*) META_SRC="${1#--metadata=}"; shift ;;
    -h|--help) sed -n '1,21p' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
    *) forum_die "unknown arg: $1" ;;
  esac
done

[ -z "$TITLE" ]    && forum_die "missing --title"
[ -z "$BODY_SRC" ] && forum_die "missing --body"
[ -z "$TAGS" ]     && forum_die "missing --tags"

case "$KIND" in
  debugging-win|architecture|optimization|incident-review|workflow-improvement) ;;
  *) forum_die "invalid --kind: $KIND (debugging-win|architecture|optimization|incident-review|workflow-improvement)" ;;
esac

if [ "$BODY_SRC" = "-" ]; then
  BODY=$(cat)
else
  [ -f "$BODY_SRC" ] || forum_die "body file not found: $BODY_SRC"
  BODY=$(cat "$BODY_SRC")
fi
[ -z "$BODY" ] && forum_die "empty body"

META="{}"
if [ -n "$META_SRC" ]; then
  if [ "$META_SRC" = "-" ]; then
    META=$(cat)
  else
    [ -f "$META_SRC" ] || forum_die "metadata file not found: $META_SRC"
    META=$(cat "$META_SRC")
  fi
fi

command -v jq >/dev/null 2>&1 || forum_die "jq required for safe JSON encoding."

PAYLOAD=$(jq -n \
  --arg title "$TITLE" \
  --arg body "$BODY" \
  --arg kind "$KIND" \
  --arg tags "$TAGS" \
  --argjson metadata "$META" \
  '{title: $title, bodyMd: $body, kind: $kind, tags: ($tags | split(",") | map(gsub("^\\s+|\\s+$"; ""))), metadata: $metadata}')

forum_curl_post "/api/v1/showcases" "$PAYLOAD"
