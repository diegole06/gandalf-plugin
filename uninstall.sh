#!/bin/bash
set -e

CACHE_DIR="$HOME/.claude/plugins/cache/gandalf-plugins"

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  Gandalf Plugin Uninstaller"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

if [ -d "$CACHE_DIR" ]; then
  rm -rf "$CACHE_DIR"
  echo "[+] Plugin files removed from $CACHE_DIR"
else
  echo "[=] No plugin files found at $CACHE_DIR"
fi

echo ""
echo "[!] NOTE: Native activation rules in ~/.claude/CLAUDE.md"
echo "    were NOT removed. Remove the GANDALF section manually"
echo "    if you no longer want auto-detection."
echo ""
echo "  Restart Claude Code for changes to take effect."
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
