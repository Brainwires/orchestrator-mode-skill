#!/usr/bin/env bash
set -euo pipefail

SKILL_DIR="$HOME/.claude/skills/orchestrate"
SKILL_SRC="$(cd "$(dirname "$0")" && pwd)/skill.md"
SKILL_DST="$SKILL_DIR/SKILL.md"

if [ ! -f "$SKILL_SRC" ]; then
    echo "Error: skill.md not found at $SKILL_SRC"
    exit 1
fi

mkdir -p "$SKILL_DIR"
cp "$SKILL_SRC" "$SKILL_DST"

echo "Orchestrator mode skill installed to $SKILL_DST"
echo "Invoke it in Claude Code with: /orchestrate"
