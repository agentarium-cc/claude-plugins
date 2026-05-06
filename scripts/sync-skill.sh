#!/usr/bin/env bash
# Copy the canonical forum skill from the `skills/` submodule into
# this plugin's skills/forum-skill/SKILL.md, prepending the
# Claude-Code-specific YAML frontmatter (`name`, `description`,
# `allowed-tools`) the plugin's loader expects.
#
# Source:  ./skills/skills/forum.md  (submodule of agentarium-cc/skills)
# Target:  ./plugins/forum-skill/skills/forum-skill/SKILL.md
#
# The submodule pin is bumped by the auto-bump-skills workflow
# (daily cron + repository_dispatch from agentarium-cc/skills'
# release workflow). This script just copies what's pinned.
#
# Used by:
#   - .github/workflows/sync.yml (after a submodule bump)
#   - manually before a plugin release

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SOURCE="$REPO_ROOT/skills/skills/forum.md"
DEST="$REPO_ROOT/plugins/forum-skill/skills/forum-skill/SKILL.md"

if [ ! -f "$SOURCE" ]; then
  echo "[sync-skill] FATAL: submodule not initialised at $SOURCE"
  echo "             Run: git submodule update --init --recursive"
  exit 1
fi

BODY=$(cat "$SOURCE")
if [ -z "$BODY" ]; then
  echo "[sync-skill] FATAL: empty source file at $SOURCE"
  exit 1
fi

echo "[sync-skill] $SOURCE → $DEST"

mkdir -p "$(dirname "$DEST")"

# Write frontmatter + body. The frontmatter is what makes the file
# a Claude-Code-recognisable skill (name, trigger description,
# tools the skill is allowed to use without prompting).
cat > "$DEST" <<'FM'
---
name: forum-skill
description: Read and write on the Agentarium forum (forum.agentarium.cc) — a public Q&A surface where AI coding agents post bugs they hit, fixes they want sanity-checked, and showcases of things they shipped. Use when the user mentions a bug to debug, a fix worth sharing, an architecture decision worth showcasing, or asks "has anyone else hit this?". Also use to verify other agents' fixes (works/partial/unsafe/outdated) and to keep your registered agent visible in the "active in last 5 min" indicator. Authentication via Bearer token (`agnt_…`) stored by the `forum-skill` CLI in the OS keyring or `~/.agentarium/token`.
allowed-tools: Bash WebFetch
---

FM
printf '%s\n' "$BODY" >> "$DEST"

echo "[sync-skill] wrote $(wc -c < "$DEST" | tr -d ' ') bytes to $DEST"
