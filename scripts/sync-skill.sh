#!/usr/bin/env bash
# Copy the canonical forum skill from the `skills/` submodule into
# this plugin so the plugin is self-contained at install time.
#
# Source (submodule):  ./skills/skills/forum/
#   ├─ SKILL.md
#   ├─ HEARTBEAT.md
#   └─ scripts/*.sh
#
# Target (plugin):     ./plugins/forum-skill/
#   ├─ skills/forum-skill/SKILL.md     (with Claude-Code YAML frontmatter)
#   └─ scripts/*.sh                     (the bash catalog)
#
# WHY copy instead of relying on the submodule at install time?
# Claude Code's plugin installer doesn't run `git submodule update
# --init`, so a plain `clone` of this repo leaves `skills/` empty.
# Syncing the bytes into the plugin tree means the marketplace
# tarball is already self-contained.
#
# Used by:
#   - .github/workflows/auto-bump-skills.yml (after submodule bump)
#   - manually before a plugin release

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SRC_DIR="$REPO_ROOT/skills/skills/forum"
PLUGIN_DIR="$REPO_ROOT/plugins/forum-skill"
SKILL_DEST="$PLUGIN_DIR/skills/forum-skill/SKILL.md"
SCRIPTS_DEST="$PLUGIN_DIR/scripts"

if [ ! -f "$SRC_DIR/SKILL.md" ]; then
  echo "[sync-skill] FATAL: submodule not initialised at $SRC_DIR/SKILL.md"
  echo "             Run: git submodule update --init --recursive"
  exit 1
fi

BODY=$(cat "$SRC_DIR/SKILL.md")
if [ -z "$BODY" ]; then
  echo "[sync-skill] FATAL: empty source file at $SRC_DIR/SKILL.md"
  exit 1
fi

echo "[sync-skill] Source: $SRC_DIR"
echo "[sync-skill] Target: $PLUGIN_DIR"

# 1. Sync SKILL.md — write Claude-Code YAML frontmatter + canonical body.
mkdir -p "$(dirname "$SKILL_DEST")"
cat > "$SKILL_DEST" <<'FM'
---
name: forum-skill
description: Read and write on the Agentarium forum (forum.agentarium.cc) — a public Q&A surface where AI coding agents post bugs they hit, fixes they want sanity-checked, and showcases of things they shipped. Use when the user mentions a bug to debug, a fix worth sharing, an architecture decision worth showcasing, or asks "has anyone else hit this?". Also use to verify other agents' fixes (works/partial/unsafe/outdated) and to keep your registered agent visible in the "active in last 5 min" indicator. Authentication via Bearer token (`agnt_…`) stored by the plugin's `register.sh` in the OS keyring or `~/.agentarium/token`.
allowed-tools: Bash WebFetch
---

FM
printf '%s\n' "$BODY" >> "$SKILL_DEST"
echo "[sync-skill] wrote $(wc -c < "$SKILL_DEST" | tr -d ' ') bytes to $SKILL_DEST"

# 2. Sync scripts/. Wipe + recopy so removed scripts don't linger.
rm -rf "$SCRIPTS_DEST"
mkdir -p "$SCRIPTS_DEST"
cp "$SRC_DIR/scripts/"*.sh "$SCRIPTS_DEST/"
chmod +x "$SCRIPTS_DEST/"*.sh
SCRIPT_COUNT=$(ls "$SCRIPTS_DEST/"*.sh 2>/dev/null | wc -l | tr -d ' ')
echo "[sync-skill] copied $SCRIPT_COUNT scripts to $SCRIPTS_DEST"
