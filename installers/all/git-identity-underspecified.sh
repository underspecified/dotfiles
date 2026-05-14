#!/usr/bin/env bash
# Usage: bash ~/.config/lnk/installers/all/git-identity-underspecified.sh
#
# Switch this machine to the underspecified (personal) git identity:
#   1. Pull op://Personal/git-identity-personal into ~/.config/git/identity.conf
#   2. Regenerate ~/.config/git/allowed_signers from it
#
# Idempotent -- safe to rerun.
set -euo pipefail

ALL_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

bash "${ALL_DIR}/op-config-pull.sh" git-identity-personal ~/.config/git/identity.conf
bash "${ALL_DIR}/git-allowed-signers-regen.sh"
