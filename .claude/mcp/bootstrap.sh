#!/usr/bin/env bash
# Usage: bash ~/.claude/mcp/bootstrap.sh
# Registers MCP servers via claude mcp add.
#
# Every server is pinned: an exact version, plus --exclude-newer, which
# freezes its dependencies at that date, so a start never pulls a new release.
# Bump by PR (~/.claude/README.md, "Versions are pinned"). Only missing
# servers are added here. An existing entry keeps its args; when they differ
# from the pinned command, this warns, and the args have to be edited.
#
# Entries are looked up in ~/.claude.json with jq, never `claude mcp list`:
# its health check starts every registered server, unpinned ones included.
#
# No `set -e`: a failed step warns and the rest still runs, and the parent
# ~/.claude/bootstrap.sh carries on to the plugin patches.
set -uo pipefail

WORKSPACE_MCP="workspace-mcp==2.1.0"
MARKITDOWN_MCP="markitdown-mcp==0.0.1a7"
MCP_APPLE_MAIL="mcp-apple-mail==3.2.0"
APPLE_MAIL_MCP="apple-mail-mcp==0.5.0"
# Dependency snapshots: the hosts' 10/16 resolve for the uvx servers, and
# apple-mail-mcp's install date for its tool env.
UVX_EXCLUDE_NEWER="2026-10-16T12:00:00Z"
TOOL_EXCLUDE_NEWER="2026-10-13T00:00:00Z"

CLAUDE_JSON="${HOME}/.claude.json"
FAILED=""

# ensure_mcp <name> <command> [args...]: add the user-scope entry when it is
# missing; warn when the registered command + args differ from the pinned ones.
ensure_mcp() {
  local name="$1" have want
  shift
  want="$*"
  have="$(jq -r --arg n "${name}" \
    '.mcpServers[$n] // empty | ([.command] + (.args // [])) | join(" ")' \
    "${CLAUDE_JSON}" 2>/dev/null || true)"
  if [[ -z "${have}" ]]; then
    echo "Adding MCP: ${name}"
    claude mcp add -s user --transport stdio "${name}" -- "$@" ||
      FAILED="${FAILED} ${name}"
  elif [[ "${have}" != "${want}" ]]; then
    echo "!! ${name}: registered args differ from the pin; edit them to: ${want}"
  fi
}

echo "--- Registering MCP servers ---"
command -v jq >/dev/null 2>&1 || {
  echo "!! jq not found -- cannot check MCP entries; skipping" >&2
  exit 1
}

# google-workspace: Drive, Docs, Sheets (filtered, no Gmail/Calendar bloat)
ensure_mcp google-workspace uvx --exclude-newer "${UVX_EXCLUDE_NEWER}" \
  "${WORKSPACE_MCP}" --tools drive docs sheets --single-user

# markitdown-mcp: document-to-markdown conversion
ensure_mcp markitdown-mcp uvx --exclude-newer "${UVX_EXCLUDE_NEWER}" "${MARKITDOWN_MCP}"

# Apple Mail (rules/email.md): work Macs only, detected by the HRI-JP OneDrive
# folder. patrickfreyer composes drafts; imdinu reads mail.
# These servers have full Mail access: on a bump, re-check settings.json's
# deny list and mail_send_gate.sh against the new release's send-capable tools.
if [[ "$(uname -s)" == "Darwin" && -d "${HOME}/Library/CloudStorage/OneDrive-HRI-JP" ]]; then
  ensure_mcp apple-mail-patrickfreyer uvx --exclude-newer "${UVX_EXCLUDE_NEWER}" \
    --with "mcp<2" "${MCP_APPLE_MAIL}"
  # imdinu's entry carries no version, so the pin lives in its uv tool env.
  # Install on every run, so an existing env also gets the version and the
  # dependency cutoff (recorded in its receipt for later `uv tool upgrade`s).
  echo "Installing ${APPLE_MAIL_MCP} (deps as of ${TOOL_EXCLUDE_NEWER})"
  uv tool install --force --prerelease allow \
    --exclude-newer "${TOOL_EXCLUDE_NEWER}" "${APPLE_MAIL_MCP}" ||
    FAILED="${FAILED} apple-mail-mcp"
  ensure_mcp apple-mail-imdinu apple-mail-mcp
else
  echo "Skipping Apple Mail MCPs: not a work Mac (no ~/Library/CloudStorage/OneDrive-HRI-JP)"
fi

if [[ -n "${FAILED}" ]]; then
  echo "!! MCP bootstrap failed for:${FAILED}" >&2
  exit 1
fi
echo "=== MCP bootstrap complete ==="
