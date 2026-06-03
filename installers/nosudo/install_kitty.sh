#!/usr/bin/env bash
# Usage: install_kitty.sh
#
# Thin wrapper around installers/linux/install_kitty.sh. The existing
# kitty installer is already user-space (curl-pipe to upstream's
# installer.sh which lays things down under ~/.local/kitty.app + drops
# bin symlinks in ~/.local/bin), so it works unchanged on nosudo hosts.
#
# Why we have a wrapper at all (rather than calling install_kitty.sh
# directly from install.sh):
#   1. Keeps installers/nosudo/ self-documenting -- every step the
#      headless path performs has a visible script here.
#   2. Gives us a future override point if the upstream installer ever
#      starts assuming root or display.
#
# On a truly headless host, the .desktop file copies and sed -i lines
# in the upstream installer are harmless no-ops -- the files land in
# ~/.local/share/applications/ but nothing reads them. The actual kitty
# binary still works as a remote-side terminfo target for `kitten ssh`.
set -euo pipefail

# shellcheck source=SCRIPTDIR/../lib.sh
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/../lib.sh"

CUR_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LINUX_DIR="${CUR_DIR}/../linux"
UPSTREAM_SCRIPT="${LINUX_DIR}/install_kitty.sh"

main() {
  [[ -f "${UPSTREAM_SCRIPT}" ]] \
    || die "expected ${UPSTREAM_SCRIPT} alongside this script"

  bash "${UPSTREAM_SCRIPT}"
}

main "$@"
