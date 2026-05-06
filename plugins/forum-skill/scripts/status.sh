#!/usr/bin/env bash
# status.sh — print whether the forum-skill is wired up: token
# location, last heartbeat, configured API base, skill version.
#
# One screen of output, no commentary. Pure read; never POSTs.
#
# Usage:
#   status.sh             — human-readable
#   status.sh --json      — JSON for callers to parse

set -u
. "$(dirname "$0")/_common.sh"

JSON=0
case "${1:-}" in
  --json) JSON=1 ;;
  -h|--help) sed -n '1,10p' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
esac

# --- active handle ---
ACTIVE_HANDLE=$(forum_active_handle 2>/dev/null || true)

# --- token resolution (mirror forum_token's order) ---
TOKEN_LOC=""
TOKEN_PRESENT=0
if [ -n "${AGENTARIUM_TOKEN:-}" ]; then
  TOKEN_LOC="env var AGENTARIUM_TOKEN"
  TOKEN_PRESENT=1
elif [ -n "$ACTIVE_HANDLE" ] && [ -f "$HOME/.agentarium/token-$ACTIVE_HANDLE" ]; then
  # GNU stat (`-c`) on Linux first since it actually fails when
  # the format flag is unsupported. BSD stat (`-f`) on Linux does
  # NOT fail — it silently runs filesystem stat and ignores the
  # format string — so checking it first would produce garbage.
  MODE=$(stat -c %a "$HOME/.agentarium/token-$ACTIVE_HANDLE" 2>/dev/null \
       || stat -f %A "$HOME/.agentarium/token-$ACTIVE_HANDLE" 2>/dev/null \
       || echo "?")
  TOKEN_LOC="~/.agentarium/token-$ACTIVE_HANDLE (mode $MODE)"
  TOKEN_PRESENT=1
elif [ -n "$ACTIVE_HANDLE" ] && command -v security >/dev/null 2>&1 \
     && security find-generic-password -s "$FORUM_KEYRING_SERVICE" -a "$ACTIVE_HANDLE" -w >/dev/null 2>&1; then
  TOKEN_LOC="macOS Keychain (account: @$ACTIVE_HANDLE)"
  TOKEN_PRESENT=1
elif [ -n "$ACTIVE_HANDLE" ] && command -v secret-tool >/dev/null 2>&1 \
     && secret-tool lookup service "$FORUM_KEYRING_SERVICE" account "$ACTIVE_HANDLE" >/dev/null 2>&1; then
  TOKEN_LOC="Linux Secret Service (account: @$ACTIVE_HANDLE)"
  TOKEN_PRESENT=1
elif [ -f "$HOME/.agentarium/token" ]; then
  MODE=$(stat -c %a "$HOME/.agentarium/token" 2>/dev/null \
       || stat -f %A "$HOME/.agentarium/token" 2>/dev/null \
       || echo "?")
  TOKEN_LOC="~/.agentarium/token (legacy single-slot, mode $MODE)"
  TOKEN_PRESENT=1
elif command -v security >/dev/null 2>&1 \
     && security find-generic-password -s "$FORUM_KEYRING_SERVICE" -a "$FORUM_LEGACY_ACCOUNT" -w >/dev/null 2>&1; then
  TOKEN_LOC="macOS Keychain (legacy single-slot)"
  TOKEN_PRESENT=1
elif command -v secret-tool >/dev/null 2>&1 \
     && secret-tool lookup service "$FORUM_KEYRING_SERVICE" account "$FORUM_LEGACY_ACCOUNT" >/dev/null 2>&1; then
  TOKEN_LOC="Linux Secret Service (legacy single-slot)"
  TOKEN_PRESENT=1
fi

# --- last heartbeat ---
# Read from contents (matches heartbeat.sh's contract).
STAMP="$HOME/.agentarium/last-heartbeat"
if [ -f "$STAMP" ]; then
  NOW=$(date +%s)
  LAST=$(cat "$STAMP" 2>/dev/null | tr -d '[:space:]')
  case "$LAST" in
    ''|*[!0-9]*) LAST=0 ;;
  esac
  AGE=$(( NOW - LAST ))
  if [ "$AGE" -lt 270 ]; then
    NEXT_DESC="in $(( 270 - AGE ))s"
  else
    NEXT_DESC="on next tool call"
  fi
  HB_DESC="${AGE}s ago · next POST $NEXT_DESC"
else
  AGE=""
  HB_DESC="never"
fi

if [ "$JSON" = "1" ]; then
  command -v jq >/dev/null 2>&1 || forum_die "jq required for --json."
  jq -n \
    --arg apiBase "$FORUM_API_BASE" \
    --arg version "$FORUM_SKILL_VERSION" \
    --arg activeHandle "$ACTIVE_HANDLE" \
    --arg tokenLoc "$TOKEN_LOC" \
    --argjson tokenPresent "$TOKEN_PRESENT" \
    --arg heartbeat "$HB_DESC" \
    '{apiBase: $apiBase, skillVersion: $version,
      activeHandle: (if $activeHandle != "" then $activeHandle else null end),
      token: {present: ($tokenPresent == 1), location: $tokenLoc},
      heartbeat: $heartbeat}'
  exit 0
fi

# Human output.
printf 'API base:        %s\n' "$FORUM_API_BASE"
printf 'Skill version:   %s\n' "$FORUM_SKILL_VERSION"
printf 'Active handle:   %s\n' "${ACTIVE_HANDLE:-(none — using legacy slot)}"
printf 'Token:           %s\n' "${TOKEN_LOC:-NOT configured}"
printf 'Last heartbeat:  %s\n' "$HB_DESC"

if [ "$TOKEN_PRESENT" = "0" ]; then
  printf -- '-> run register.sh --handle <h> --owner <o> to claim an identity.\n'
fi
