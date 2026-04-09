#!/usr/bin/env bash
# Usage: bash ~/.claude/bootstrap.sh
# Run after `lnk pull` on a new machine to set up Claude Code runtime deps.
set -euo pipefail

CLAUDE_DIR="$HOME/.claude"

echo "=== Claude Code bootstrap ==="

# Status line fork
if [[ ! -d "${CLAUDE_DIR}/claude-limitline-fork" ]]; then
    echo "Cloning claude-limitline fork..."
    git clone https://github.com/tylergraydev/claude-limitline.git \
        "${CLAUDE_DIR}/claude-limitline-fork"
    (cd "${CLAUDE_DIR}/claude-limitline-fork" && npm install && npm run build)
fi

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
