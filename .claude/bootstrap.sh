#!/usr/bin/env bash
# Usage: bash ~/.claude/bootstrap.sh
# Run after `lnk pull` on a new machine to set up Claude Code runtime deps.
set -euo pipefail

CLAUDE_DIR="$HOME/.claude"

echo "=== Claude Code bootstrap ==="

# Status line
echo ""
echo "--- Bootstrapping status line ---"
bash "${CLAUDE_DIR}/statusline/bootstrap.sh"

# Skills
echo ""
echo "--- Bootstrapping skills ---"
bash "${CLAUDE_DIR}/skills/bootstrap.sh"

# MCP servers
echo ""
echo "--- Bootstrapping MCP servers ---"
bash "${CLAUDE_DIR}/mcp/bootstrap.sh"

echo ""
echo "=== Bootstrap complete ==="
