#!/usr/bin/env bash
# Usage: bash ~/.config/lnk/installers/macos/post_upgrade.sh
#
# Run after a macOS update. Fixes what updates have broken before:
# - Rosetta 2: updates remove it (27.0 on 10/9, 27.2.1 on 11/15). Without it the
#   Intel-only ManageEngine MDM agent can't start, and its watchdog then asks
#   for sudo every 60 s.
# Idempotent; asks for sudo only when something needs fixing.
set -uo pipefail

# shellcheck source=SCRIPTDIR/../lib.sh
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/../lib.sh"

rosetta_works() { /usr/bin/arch -x86_64 /usr/bin/true 2>/dev/null; }

ensure_rosetta() {
  if rosetta_works; then
    log "Rosetta: OK"
    return 0
  fi
  log "Rosetta: missing, installing (needs sudo)"
  sudo /usr/sbin/softwareupdate --install-rosetta --agree-to-license ||
    die "Rosetta install failed"
  rosetta_works || die "Rosetta installed but x86_64 binaries still don't run"
  log "Rosetta: installed"
}

main() {
  [[ "$(uname -m)" == "arm64" ]] || die "post_upgrade.sh is for Apple silicon Macs"
  ensure_rosetta
}

main "$@"
