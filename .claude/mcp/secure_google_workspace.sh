#!/usr/bin/env bash
# Usage: bash ~/.claude/mcp/secure_google_workspace.sh
# Output: "<mode> <path>" per secret, plus "(was <mode>)" for each one it fixed.
#
# Makes the Google Workspace MCP's secrets owner-only: the OAuth tokens under
# ~/.google_workspace_mcp/credentials (0600, dir 0700) and the OAuth client
# secret files (0600). Prints paths and modes only, never contents. Idempotent;
# run it again after any sign-in.
#
# workspace-mcp creates token files 0600 and keeps an existing file's mode when
# it rewrites one, but another writer left a token at 0644 (11/14).
set -uo pipefail

base="${HOME}/.google_workspace_mcp"

mode_of() { stat -f '%Lp' "$1" 2>/dev/null || stat -c '%a' "$1"; }

# tighten <mode> <path>: chmod when the mode differs; report either way.
tighten() {
  local want="$1" path="$2" have
  [[ -e "${path}" ]] || return 0
  have="$(mode_of "${path}")"
  if [[ "${have}" == "${want}" ]]; then
    echo "${want} ${path}"
  elif chmod "${want}" "${path}"; then
    echo "${want} ${path} (was ${have})"
  else
    echo "!! could not chmod ${path} (still ${have})" >&2
    return 1
  fi
}

main() {
  local rc=0 f secret
  secret="$(jq -r '.mcpServers["google-workspace"].env.GOOGLE_CLIENT_SECRET_PATH // empty' \
    "${HOME}/.claude.json" 2>/dev/null || true)"
  tighten 700 "${base}" || rc=1
  tighten 700 "${base}/credentials" || rc=1
  for f in "${base}"/credentials/*.json "${base}/client_secret.json" ${secret:+"${secret}"}; do
    tighten 600 "${f}" || rc=1
  done
  return "${rc}"
}

main "$@"
