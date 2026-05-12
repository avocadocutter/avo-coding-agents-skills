#!/usr/bin/env bash
set -e

SKILL_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TOOL="${1:-claude}"
PROJECT="${2:-$(pwd)}"

case "$TOOL" in
  claude)
    DEST="$PROJECT/.claude/skills/test-audit"
    mkdir -p "$DEST/references"
    cp "$SKILL_DIR/skill.md" "$DEST/SKILL.md"
    cp "$SKILL_DIR/references/solid-test-criteria.md" "$DEST/references/solid-test-criteria.md"
    echo "Installed test-audit → $DEST"
    ;;
  cursor)
    DEST="$PROJECT/.cursor/rules"
    mkdir -p "$DEST"
    cp "$SKILL_DIR/skill.md" "$DEST/test-audit.mdc"
    echo "Installed test-audit → $DEST/test-audit.mdc"
    ;;
  *)
    echo "Unknown tool: $TOOL"
    echo "Usage: ./install.sh [claude|cursor] [project-path]"
    exit 1
    ;;
esac
