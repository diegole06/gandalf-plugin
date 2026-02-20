#!/bin/bash
set -e

PLUGIN_NAME="gandalf"
VERSION="1.0.0"
CACHE_DIR="$HOME/.claude/plugins/cache/gandalf-plugins/$PLUGIN_NAME/$VERSION"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  Gandalf Plugin Installer v$VERSION"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

if [ -d "$CACHE_DIR" ]; then
  echo "[!] Existing installation found at $CACHE_DIR"
  echo "    Replacing..."
  rm -rf "$CACHE_DIR"
fi

mkdir -p "$CACHE_DIR"

cp -r "$SCRIPT_DIR/.claude-plugin" "$CACHE_DIR/"
cp -r "$SCRIPT_DIR/commands" "$CACHE_DIR/"
cp -r "$SCRIPT_DIR/skills" "$CACHE_DIR/"

echo "[+] Plugin files installed to: $CACHE_DIR"

CLAUDE_MD="$HOME/.claude/CLAUDE.md"
MARKER="## GANDALF — NATIVE ACTIVATION RULES"

if [ -f "$CLAUDE_MD" ] && grep -q "$MARKER" "$CLAUDE_MD" 2>/dev/null; then
  echo "[=] Native activation rules already present in $CLAUDE_MD"
else
  echo ""
  echo "[?] Do you want to add native activation rules to $CLAUDE_MD?"
  echo "    This makes Gandalf auto-detect Jira URLs, ticket IDs, and investigation keywords"
  echo "    without needing to type /gandalf:analyze explicitly."
  echo ""
  read -p "    Add native activation? (y/n): " -n 1 -r
  echo ""

  if [[ $REPLY =~ ^[Yy]$ ]]; then
    if [ -f "$SCRIPT_DIR/claude-md-snippet.md" ]; then
      echo "" >> "$CLAUDE_MD"
      cat "$SCRIPT_DIR/claude-md-snippet.md" >> "$CLAUDE_MD"
      echo "[+] Native activation rules added to $CLAUDE_MD"
    else
      echo "[!] claude-md-snippet.md not found. Copy it manually from the repo."
    fi
  else
    echo "[=] Skipped. You can add it later from claude-md-snippet.md"
  fi
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  Installation complete!"
echo ""
echo "  Commands available:"
echo "    /gandalf:analyze   — Investigate a ticket/incident"
echo "    /gandalf:fix       — Implement the fix (TDD)"
echo "    /gandalf:summary   — Generate Slack/standup summary"
echo "    /gandalf:core-pr-plan — Cross-team PR plan"
echo ""
echo "  Restart Claude Code for changes to take effect."
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
