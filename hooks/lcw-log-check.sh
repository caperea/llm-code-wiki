#!/usr/bin/env bash
# LCW Stop Hook: check if wiki files were modified but log.md was not updated.
# Safety net — normally the maintenance subagent handles log.md.

WIKI_PATTERN="^(repos|modules|systems|interfaces|flows|domains|issues|ddd)/"
SINGLE_FILES="^(overview|glossary)\.md$"

WIKI_CHANGED=$(git diff --name-only 2>/dev/null | grep -E "$WIKI_PATTERN|$SINGLE_FILES")
LOG_CHANGED=$(git diff --name-only 2>/dev/null | grep -q "^log\.md$" && echo "yes")

if [ -n "$WIKI_CHANGED" ] && [ -z "$LOG_CHANGED" ]; then
  COUNT=$(echo "$WIKI_CHANGED" | wc -l | tr -d ' ')
  echo "[lcw] $COUNT wiki file(s) modified but log.md not updated. Please append a log entry."
fi
