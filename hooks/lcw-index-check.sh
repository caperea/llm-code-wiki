#!/usr/bin/env bash
# LCW Stop Hook: check if pages were added/deleted but index.md was not updated.
# Safety net — normally the maintenance subagent handles index.md.

ADDED=$(git diff --name-only --diff-filter=A 2>/dev/null | grep '\.md$' | grep -v '^\.\(inputs\|sources\)/' | grep -v '^log\.md$')
DELETED=$(git diff --name-only --diff-filter=D 2>/dev/null | grep '\.md$' | grep -v '^\.\(inputs\|sources\)/' | grep -v '^log\.md$')

INDEX_CHANGED=$(git diff --name-only 2>/dev/null | grep -q "^index\.md$" && echo "yes")

if { [ -n "$ADDED" ] || [ -n "$DELETED" ]; } && [ -z "$INDEX_CHANGED" ]; then
  echo "[lcw] Wiki pages added/deleted but index.md not updated:"
  [ -n "$ADDED" ] && echo "  Added: $(echo "$ADDED" | tr '\n' ' ')"
  [ -n "$DELETED" ] && echo "  Removed: $(echo "$DELETED" | tr '\n' ' ')"
fi
