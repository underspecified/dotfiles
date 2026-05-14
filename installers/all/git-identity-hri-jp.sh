#!/usr/bin/env bash
# Usage: bash ~/.config/lnk/installers/all/git-identity-hri-jp.sh
#
# Switch this machine to the hri_jp (work) git identity:
#   1. Pull op://Personal/git-identity-work into ~/.config/git/identity.conf
#   2. Regenerate ~/.config/git/allowed_signers from it
#
# Idempotent -- safe to rerun.
set -euo pipefail

ALL_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

bash "${ALL_DIR}/op-config-pull.sh" git-identity-work ~/.config/git/identity.conf
bash "${ALL_DIR}/git-allowed-signers-regen.sh"
