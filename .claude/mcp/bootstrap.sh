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

# Apple Mail (rules/email.md): work Macs only, detected by the HRI-JP OneDrive
# folder. patrickfreyer composes drafts; imdinu reads mail.
if [[ "$(uname -s)" == "Darwin" && -d "${HOME}/Library/CloudStorage/OneDrive-HRI-JP" ]]; then
  if ! claude mcp list 2>/dev/null | grep -q "^apple-mail-patrickfreyer:"; then
    echo "Adding MCP: apple-mail-patrickfreyer"
    claude mcp add -s user --transport stdio apple-mail-patrickfreyer \
      -- uvx --with "mcp<2" mcp-apple-mail
  fi
  if ! claude mcp list 2>/dev/null | grep -q "^apple-mail-imdinu:"; then
    echo "Adding MCP: apple-mail-imdinu"
    uv tool install --prerelease allow apple-mail-mcp
    claude mcp add -s user --transport stdio apple-mail-imdinu \
      -- apple-mail-mcp
  fi
else
  echo "Skipping Apple Mail MCPs: not a work Mac (no ~/Library/CloudStorage/OneDrive-HRI-JP)"
fi

echo "=== MCP bootstrap complete ==="
