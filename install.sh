#!/usr/bin/env bash
set -e

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SKILL="$1"
TOOL="$2"
PROJECT="${3:-$(pwd)}"

# Update these when install paths are re-verified against new releases
# Claude Code — .claude/skills/<name>/SKILL.md
# Cursor      — .cursor/rules/<name>.mdc
CLAUDE_TESTED="2.1.139"
CURSOR_TESTED="3.3.0"

if [[ -z "$SKILL" || -z "$TOOL" ]]; then
  echo "Usage: ./install.sh <skill-name> <claude|cursor> [project-path]"
  echo ""
  echo "Available skills:"
  ls "$REPO_DIR" | grep -v 'install.sh\|^\.' | sed 's/^/  /'
  exit 1
fi

SKILL_DIR="$REPO_DIR/$SKILL"

if [[ ! -d "$SKILL_DIR" ]]; then
  echo "Skill '$SKILL' not found."
  echo ""
  echo "Available skills:"
  ls "$REPO_DIR" | grep -v 'install.sh\|^\.' | sed 's/^/  /'
  exit 1
fi

check_version() {
  local tool="$1"
  local tested_version="$2"
  local docs_url="$3"
  local version

  case "$tool" in
    claude) version=$(claude --version 2>/dev/null | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | head -1) ;;
    cursor) version=$(cursor --version 2>/dev/null | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | head -1) ;;
  esac

  if [[ -z "$version" ]]; then
    printf "1/3  Compatibility ... WARNING  could not detect %s version\n" "$tool"
    printf "     docs: %s\n" "$docs_url"
    printf "     continue anyway? [y/N] "
    read -r answer
    [[ "$answer" =~ ^[Yy]$ ]] || { echo "     Aborted."; exit 1; }
  else
    local maj_min tested_maj_min
    maj_min=$(echo "$version" | cut -d. -f1-2)
    tested_maj_min=$(echo "$tested_version" | cut -d. -f1-2)
    if [[ "$maj_min" != "$tested_maj_min" ]]; then
      printf "1/3  Compatibility ... WARNING  %s %s detected, paths verified on %s\n" "$tool" "$version" "$tested_version"
      printf "     docs: %s\n" "$docs_url"
      printf "     continue anyway? [y/N] "
      read -r answer
      [[ "$answer" =~ ^[Yy]$ ]] || { echo "     Aborted."; exit 1; }
    else
      printf "1/3  Compatibility ... %s %s  OK\n" "$tool" "$version"
    fi
  fi
}

echo ""
echo "$SKILL  →  $TOOL"
echo ""

case "$TOOL" in
  claude)
    check_version claude "$CLAUDE_TESTED" "https://docs.claude.ai/en/docs/claude-code/slash-commands"
    DEST="$PROJECT/.claude/skills/$SKILL"
    printf "2/3  Installing   ... "
    mkdir -p "$DEST/references"
    cp "$SKILL_DIR/skill.md" "$DEST/SKILL.md"
    if [[ -d "$SKILL_DIR/references" ]] && ls "$SKILL_DIR/references/"* &>/dev/null; then
      cp "$SKILL_DIR/references/"* "$DEST/references/"
    fi
    echo "done"
    echo "     $DEST/SKILL.md"
    if [[ -d "$DEST/references" ]] && ls "$DEST/references/"* &>/dev/null; then
      echo "     $DEST/references/"
    fi
    echo ""
    echo "3/3  Ready"
    echo "     Open the project in Claude Code and type /$SKILL"
    ;;
  cursor)
    check_version cursor "$CURSOR_TESTED" "https://docs.cursor.com/context/rules"
    DEST="$PROJECT/.cursor/rules"
    printf "2/3  Installing   ... "
    mkdir -p "$DEST"
    cp "$SKILL_DIR/skill.md" "$DEST/$SKILL.mdc"
    echo "done"
    echo "     $DEST/$SKILL.mdc"
    echo ""
    echo "3/3  Ready"
    echo "     Open the project in Cursor and type @$SKILL"
    echo "     (or leave it — applies automatically based on trigger conditions)"
    ;;
  *)
    echo "Unknown tool: $TOOL. Use 'claude' or 'cursor'."
    exit 1
    ;;
esac
echo ""
