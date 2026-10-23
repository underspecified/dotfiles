#!/usr/bin/env bash
# Usage: bash ~/.claude/mcp/bootstrap.sh
# Registers MCP servers via claude mcp add.
#
# Every server is pinned: an exact version, plus --exclude-newer at the date
# its dependencies were last resolved, so a start never pulls a new release.
# Bump by PR (~/.claude/README.md, "Versions are pinned"). Only missing
# servers are added here; an existing registration keeps its old args until
# they are edited.
set -euo pipefail

# Dependency snapshot for the uvx servers, and for the apple-mail-mcp tool.
UVX_EXCLUDE_NEWER="2026-10-23T00:00:00Z"
TOOL_EXCLUDE_NEWER="2026-10-13T00:00:00Z"

echo "--- Registering MCP servers ---"

# google-workspace: Drive, Docs, Sheets (filtered, no Gmail/Calendar bloat)
if ! claude mcp list 2>/dev/null | grep -q "^google-workspace:"; then
  echo "Adding MCP: google-workspace (drive/docs/sheets)"
  claude mcp add -s user --transport stdio google-workspace \
    -- uvx --exclude-newer "${UVX_EXCLUDE_NEWER}" "workspace-mcp==2.1.2" \
    --tools drive docs sheets --single-user
fi

# markitdown-mcp: document-to-markdown conversion
if ! claude mcp list 2>/dev/null | grep -q "^markitdown-mcp:"; then
  echo "Adding MCP: markitdown-mcp"
  claude mcp add -s user --transport stdio markitdown-mcp \
    -- uvx --exclude-newer "${UVX_EXCLUDE_NEWER}" "markitdown-mcp==0.0.1a8"
fi

# Apple Mail (rules/email.md): work Macs only, detected by the HRI-JP OneDrive
# folder. patrickfreyer composes drafts; imdinu reads mail.
# These servers have full Mail access: on a bump, re-check settings.json's
# deny list and mail_send_gate.sh against the new release's send-capable tools.
if [[ "$(uname -s)" == "Darwin" && -d "${HOME}/Library/CloudStorage/OneDrive-HRI-JP" ]]; then
  if ! claude mcp list 2>/dev/null | grep -q "^apple-mail-patrickfreyer:"; then
    echo "Adding MCP: apple-mail-patrickfreyer"
    claude mcp add -s user --transport stdio apple-mail-patrickfreyer \
      -- uvx --exclude-newer "${UVX_EXCLUDE_NEWER}" --with "mcp<2" "mcp-apple-mail==3.2.0"
  fi
  if ! claude mcp list 2>/dev/null | grep -q "^apple-mail-imdinu:"; then
    echo "Adding MCP: apple-mail-imdinu"
    uv tool install --force --prerelease allow \
      --exclude-newer "${TOOL_EXCLUDE_NEWER}" "apple-mail-mcp==0.5.0"
    claude mcp add -s user --transport stdio apple-mail-imdinu \
      -- apple-mail-mcp
  fi
else
  echo "Skipping Apple Mail MCPs: not a work Mac (no ~/Library/CloudStorage/OneDrive-HRI-JP)"
fi

echo "=== MCP bootstrap complete ==="
