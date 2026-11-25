#!/usr/bin/env bash
# Usage: bash ~/.claude/mcp/bootstrap.sh
# Registers MCP servers via claude mcp add.
#
# Every server is pinned: an exact version, plus --exclude-newer, which
# freezes its dependencies at that date, so a start never pulls a new release.
# Bump by PR (~/.claude/README.md, "Versions are pinned"). Only missing
# servers are added here. An existing entry is left as it is; when it differs
# from the pin, this warns, and the entry has to be registered again.
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
# The servers that fetch verify TLS through the OS trust store (README, "TLS
# goes through the OS trust store"). Absolute path: an MCP env expands no ~.
TRUSTSTORE="truststore==0.10.5"
TRUSTSTORE_DIR="${HOME}/.claude/mcp/truststore"
# Dependency snapshots: the hosts' 10/16 resolve for the uvx servers, and
# apple-mail-mcp's install date for its tool env.
UVX_EXCLUDE_NEWER="2026-10-16T12:00:00Z"
TOOL_EXCLUDE_NEWER="2026-10-13T00:00:00Z"

CLAUDE_JSON="${HOME}/.claude.json"
FAILED=""

# ensure_mcp <name> [-e KEY=VALUE]... <command> [args...]: add the user-scope
# entry when it is missing. Warn when a registered one differs from the pin in
# its command + args or in a pinned env key; its other env keys are the host's.
ensure_mcp() {
  local name="$1" have want kv
  local -a env=() flags=()
  shift
  while [[ "${1:-}" == "-e" ]]; do
    env+=("$2")
    flags+=(-e "$2")
    shift 2
  done
  want="$*"
  have="$(jq -r --arg n "${name}" \
    '.mcpServers[$n] // empty | ([.command] + (.args // [])) | join(" ")' \
    "${CLAUDE_JSON}" 2>/dev/null || true)"
  if [[ -z "${have}" ]]; then
    echo "Adding MCP: ${name}"
    # -e takes any number of values, so it follows the name and `--` ends it.
    claude mcp add -s user --transport stdio "${name}" \
      ${flags[@]+"${flags[@]}"} -- "$@" || FAILED="${FAILED} ${name}"
    return
  fi
  [[ "${have}" == "${want}" ]] ||
    echo "!! ${name}: registered args differ from the pin; register it again with: ${want}"
  for kv in ${env[@]+"${env[@]}"}; do
    # Compared inside jq, so a registered value is never printed.
    jq -e --arg n "${name}" --arg k "${kv%%=*}" --arg v "${kv#*=}" \
      '.mcpServers[$n].env[$k] == $v' "${CLAUDE_JSON}" >/dev/null 2>&1 ||
      echo "!! ${name}: env ${kv%%=*} is missing or differs from the pin; want ${kv}"
  done
}

echo "--- Registering MCP servers ---"
command -v jq >/dev/null 2>&1 || {
  echo "!! jq not found -- cannot check MCP entries; skipping" >&2
  exit 1
}
# Python skips a PYTHONPATH entry that does not exist, without a word.
[[ -f "${TRUSTSTORE_DIR}/sitecustomize.py" ]] ||
  echo "!! ${TRUSTSTORE_DIR}/sitecustomize.py is missing (run lnk pull): TLS falls back to certifi"

# google-workspace: Drive, Docs, Sheets (filtered, no Gmail/Calendar bloat)
ensure_mcp google-workspace -e "PYTHONPATH=${TRUSTSTORE_DIR}" \
  uvx --exclude-newer "${UVX_EXCLUDE_NEWER}" --with "${TRUSTSTORE}" \
  "${WORKSPACE_MCP}" --tools drive docs sheets --single-user

# markitdown-mcp: document-to-markdown conversion, from files and URLs
ensure_mcp markitdown-mcp -e "PYTHONPATH=${TRUSTSTORE_DIR}" \
  uvx --exclude-newer "${UVX_EXCLUDE_NEWER}" --with "${TRUSTSTORE}" "${MARKITDOWN_MCP}"

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
