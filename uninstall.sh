#!/usr/bin/env bash
set -e

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SKILL="$1"
TOOL="$2"
PROJECT="${3:-$(pwd)}"

if [[ -z "$SKILL" || -z "$TOOL" ]]; then
  echo "Usage: ./uninstall.sh <skill-name> <claude|cursor> [project-path]"
  echo "Available skills: $(ls "$REPO_DIR" | grep -v -E '(install|uninstall)\.sh' | grep -v '^\.' | tr '\n' ' ')"
  exit 1
fi

echo "Uninstalling '$SKILL' for $TOOL from: $PROJECT"
echo ""

case "$TOOL" in
  claude)
    DEST="$PROJECT/.claude/skills/$SKILL"
    if [[ ! -d "$DEST" ]]; then
      echo "Skill '$SKILL' is not installed at $DEST"
      exit 1
    fi
    read -r -p "  Remove $DEST? [y/N] " confirm
    [[ "$confirm" =~ ^[Yy]$ ]] || { echo "Aborted."; exit 0; }
    rm -rf "$DEST"
    echo ""
    echo "Done! Skill '$SKILL' removed."
    ;;
  cursor)
    DEST="$PROJECT/.cursor/rules/$SKILL.mdc"
    if [[ ! -f "$DEST" ]]; then
      echo "Skill '$SKILL' is not installed at $DEST"
      exit 1
    fi
    read -r -p "  Remove $DEST? [y/N] " confirm
    [[ "$confirm" =~ ^[Yy]$ ]] || { echo "Aborted."; exit 0; }
    rm "$DEST"
    echo ""
    echo "Done! Skill '$SKILL' removed."
    ;;
  *)
    echo "Unknown tool: $TOOL"
    echo "Usage: ./uninstall.sh <skill-name> <claude|cursor> [project-path]"
    exit 1
    ;;
esac
