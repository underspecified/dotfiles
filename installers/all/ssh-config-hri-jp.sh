#!/usr/bin/env bash
# Usage: bash ~/.config/lnk/installers/all/ssh-config-hri-jp.sh
#
# Pull the HRI-JP (work) SSH host snippet from 1Password
# (op://Personal/ssh-config-hri-jp) into ~/.ssh/config.d/hri_jp,
# where it is picked up by the `Include ~/.ssh/config.d/*` directive
# in the main ssh config.
#
# Idempotent -- safe to rerun.
set -euo pipefail

ALL_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

bash "${ALL_DIR}/op-config-pull.sh" ssh-config-hri-jp ~/.ssh/config.d/hri_jp
