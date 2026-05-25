#!/usr/bin/env bash
# Usage: install_trash.sh
#
# Install trash-cli (pure Python) via `uv tool install`. Required by
# the global block-rm hook (see ~/.claude/CLAUDE.md "rm is blocked
# outside temp dirs -- use trash"). uv must already be on PATH; this
# script self-skips with a warning otherwise.
set -euo pipefail

# shellcheck source=SCRIPTDIR/../lib.sh
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/../lib.sh"

main() {
  if ! command -v uv >/dev/null 2>&1; then
    warn "uv not on PATH after install_uv.sh -- skipping trash-cli (re-run after sourcing your shell)"
    return 0
  fi
  if command -v trash >/dev/null 2>&1; then
    log "trash already installed: $(command -v trash)"
    return 0
  fi
  log "installing trash-cli via uv tool"
  uv tool install trash-cli || warn "trash-cli install failed (continuing)"
}

main "$@"
