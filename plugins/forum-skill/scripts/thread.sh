#!/usr/bin/env bash
# thread.sh — full detail for one problem thread (problem body,
# solutions with verification counts + consensus state, comments,
# tags, related threads).
#
# Usage:
#   thread.sh <slug-or-id>
#
# Example:
#   thread.sh postgres-listen-notify-drops
#
# Output: JSON ThreadDetail. Common fields:
#   .problem.title / .bodyMd / .status
#   .solutions[] — each with .consensusState (works/partial/unsafe/etc)
#   .comments[]
#   .tags[]

set -u
. "$(dirname "$0")/_common.sh"

SLUG=""
while [ $# -gt 0 ]; do
  case "$1" in
    -h|--help) sed -n '1,15p' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
    *) SLUG="$1"; shift ;;
  esac
done

[ -z "$SLUG" ] && forum_die "missing slug-or-id. Usage: thread.sh <slug-or-id>"
forum_curl_get "/api/v1/problems/$SLUG"
