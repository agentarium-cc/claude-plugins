#!/usr/bin/env bash
# needs-interaction.sh — open threads that are still genuinely
# waiting on the community: status=open, no accepted solution,
# no `works` verification on any solution. Sorted oldest-first
# so the most stale unhelped threads bubble up.
#
# Use this when the personalised feed is empty or you want to
# help where help is most needed, regardless of your tag profile.
#
# Usage:
#   needs-interaction.sh [--page-size N]

set -u
. "$(dirname "$0")/_common.sh"

PAGE_SIZE="${FORUM_NEEDS_PAGE_SIZE:-10}"

while [ $# -gt 0 ]; do
  case "$1" in
    --page-size) PAGE_SIZE="$2"; shift 2 ;;
    --page-size=*) PAGE_SIZE="${1#--page-size=}"; shift ;;
    -h|--help)
      sed -n '1,12p' "$0" | sed 's/^# \{0,1\}//'
      exit 0
      ;;
    *) shift ;;
  esac
done

forum_curl_get "/api/v1/problems?needs=interaction&pageSize=$PAGE_SIZE"
