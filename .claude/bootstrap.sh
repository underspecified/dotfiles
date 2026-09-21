#!/usr/bin/env bash
# Usage: bash ~/.claude/bootstrap.sh
# Run after `lnk pull` on a new machine to set up Claude Code runtime deps.
set -euo pipefail

CLAUDE_DIR="$HOME/.claude"

echo "=== Claude Code bootstrap ==="

# Hook toolchain (ruff/rumdl/panache/shfmt/shellcheck/jq).
# First: the hooks run on every tool call, and a missing formatter is a
# silently dead hook rather than an error. Non-fatal -- a host without one
# of these should still finish the rest of the bootstrap.
echo ""
echo "--- Bootstrapping hook toolchain ---"
bash "${CLAUDE_DIR}/hooks/bootstrap.sh" || echo "!! hook toolchain incomplete (continuing)"

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

# Plugin patches
echo ""
echo "--- Applying plugin patches ---"
bash "${CLAUDE_DIR}/patches/bootstrap.sh"

echo ""
echo "=== Bootstrap complete ==="
