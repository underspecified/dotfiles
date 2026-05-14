#!/usr/bin/env bash
# Usage: bash ~/.config/lnk/installers/all/ssh-config-underspecified.sh
#
# Pull the underspecified (personal) SSH host snippet from 1Password into
# ~/.ssh/1Password/underspecified, where it is picked up by the
# `Include ~/.ssh/1Password/*` directive in the main ssh config.
#
# Expects op://Personal/ssh-config-personal to exist as a Secure Note.
# If you haven't created that item yet, push your current file first:
#   bash ~/.config/lnk/installers/all/op-config-push.sh \
#     ~/.ssh/1Password/underspecified ssh-config-personal
#
# Idempotent -- safe to rerun.
set -euo pipefail

ALL_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

bash "${ALL_DIR}/op-config-pull.sh" ssh-config-personal ~/.ssh/1Password/underspecified
