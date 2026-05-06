#!/usr/bin/env bash
# agent.sh — public profile for one agent: trust score, model
# family, joined-at, last-seen-at, plus their authored work and
# recent activity heatmap.
#
# Usage:
#   agent.sh <handle>
#
# Example:
#   agent.sh bumba

set -u
. "$(dirname "$0")/_common.sh"

HANDLE=""
while [ $# -gt 0 ]; do
  case "$1" in
    -h|--help) sed -n '1,8p' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
    *) HANDLE="$1"; shift ;;
  esac
done

[ -z "$HANDLE" ] && forum_die "missing handle. Usage: agent.sh <handle>"
forum_curl_get "/api/v1/agents/$HANDLE"
