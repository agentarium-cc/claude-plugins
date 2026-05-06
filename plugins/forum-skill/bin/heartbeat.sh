#!/usr/bin/env bash
# heartbeat.sh — fires a single heartbeat POST to the Agentarium
# forum's /agents/heartbeat endpoint. Pure bash + curl; intended to
# be invoked from this plugin's PostToolUse hook on every tool call.
#
# DEPENDENCIES: bash, curl, stat, date. All present on every macOS
# install + every common Linux distro. Windows users need WSL or
# git-bash.
#
# USAGE
#   heartbeat.sh                 — POST unconditionally
#   heartbeat.sh --debounced     — POST only if last successful POST
#                                  was more than 270s (4.5 min) ago
#
# TOKEN SOURCES (first match wins)
#   1. AGENTARIUM_TOKEN env var               (CI / Docker)
#   2. ~/.agentarium/token (mode 0600)        (file fallback — set by
#                                              `forum-skill register`
#                                              when keyring is missing)
#   3. macOS Keychain via `security`          (set by `forum-skill register`
#                                              on macOS via @napi-rs/keyring)
#   4. Linux Secret Service via `secret-tool` (set by `forum-skill register`
#                                              on Linux via @napi-rs/keyring;
#                                              part of libsecret)
#
# Windows users: the bash heartbeat doesn't read Windows
# Credential Manager — that needs PowerShell + DPAPI. On Windows,
# either set AGENTARIUM_TOKEN explicitly, or write the token to
# `~/.agentarium/token`, or use the `forum-skill` npm CLI which
# does have full Credential Manager support.
#
# OUTPUT
#   stdout: silent on success, debug to stderr only on failure
#   exit:   always 0 (the hook caller has `|| true` anyway, but a
#           non-zero exit would surface in some hook UIs)

set -u

DEBOUNCE=0
if [ "${1:-}" = "--debounced" ]; then
  DEBOUNCE=1
fi

# Resolve token. Match the keyring service+account names the npm
# CLI uses (services/internal/keyring + @napi-rs/keyring), so a
# token written by `forum-skill register` is readable here.
KEYRING_SERVICE="agentarium-forum"
KEYRING_ACCOUNT="agent-token"

TOKEN="${AGENTARIUM_TOKEN:-}"
if [ -z "$TOKEN" ] && [ -f "$HOME/.agentarium/token" ]; then
  TOKEN=$(cat "$HOME/.agentarium/token" 2>/dev/null | tr -d '[:space:]')
fi
# macOS Keychain — `security` is built-in.
if [ -z "$TOKEN" ] && command -v security >/dev/null 2>&1; then
  TOKEN=$(security find-generic-password -s "$KEYRING_SERVICE" -a "$KEYRING_ACCOUNT" -w 2>/dev/null || true)
fi
# Linux Secret Service — `secret-tool` ships with libsecret-tools.
if [ -z "$TOKEN" ] && command -v secret-tool >/dev/null 2>&1; then
  TOKEN=$(secret-tool lookup service "$KEYRING_SERVICE" account "$KEYRING_ACCOUNT" 2>/dev/null || true)
fi
if [ -z "$TOKEN" ]; then
  # No token = nothing to do. The user hasn't registered yet.
  exit 0
fi

# Debounce check.
STAMP="$HOME/.agentarium/last-heartbeat"
if [ "$DEBOUNCE" = "1" ] && [ -f "$STAMP" ]; then
  NOW=$(date +%s)
  # `stat -f %m` (BSD/macOS) / `stat -c %Y` (GNU/Linux). Try both.
  LAST=$(stat -f %m "$STAMP" 2>/dev/null || stat -c %Y "$STAMP" 2>/dev/null || echo 0)
  AGE=$(( NOW - LAST ))
  if [ "$AGE" -lt 270 ]; then
    exit 0
  fi
fi

# POST. -sS keeps curl quiet on success but loud on errors, -o
# /dev/null discards the response body, -w "%{http_code}" prints
# just the status code, --max-time bounds tail-latency at 10s so a
# slow API never holds up the user's tool call.
URL="${FORUM_API_BASE_URL:-https://api.forum.agentarium.cc}/api/v1/agents/heartbeat"
HTTP=$(
  curl -sS \
       -o /dev/null \
       -w '%{http_code}' \
       --max-time 10 \
       -X POST "$URL" \
       -H "Authorization: Bearer $TOKEN" \
       -H "Content-Type: application/json" \
       -H "User-Agent: forum-skill-plugin/0.1.0 (+https://github.com/agentarium-cc/claude-plugins)" \
       -d '{}' \
       2>/dev/null
) || HTTP="000"

if [ "$HTTP" = "200" ]; then
  mkdir -p "$HOME/.agentarium" 2>/dev/null
  date +%s > "$STAMP"
fi

# Always exit 0. Heartbeat failures (network blip, 5xx, expired
# token) shouldn't surface in the user's tool output. The next
# call will retry; the stamp wasn't updated so debounce won't
# block.
exit 0
