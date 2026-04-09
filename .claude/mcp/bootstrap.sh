#!/usr/bin/env bash
# Usage: bash ~/.claude/mcp/bootstrap.sh
# Registers MCP servers via claude mcp add.
set -euo pipefail

echo "--- Registering MCP servers ---"

# google-workspace: Drive, Docs, Sheets (filtered, no Gmail/Calendar bloat)
if ! claude mcp list 2>/dev/null | grep -q "^google-workspace:"; then
    echo "Adding MCP: google-workspace (drive/docs/sheets)"
    claude mcp add -s user --transport stdio google-workspace \
        -- uvx workspace-mcp --tools drive docs sheets --single-user
fi

# markitdown-mcp: document-to-markdown conversion
if ! claude mcp list 2>/dev/null | grep -q "^markitdown-mcp:"; then
    echo "Adding MCP: markitdown-mcp"
    claude mcp add -s user --transport stdio markitdown-mcp \
        -- uvx markitdown-mcp
fi

echo "=== MCP bootstrap complete ==="
