#!/usr/bin/env bash
# Auto-run by `lnk init -r <url>` after the repo is cloned and symlinks
# are restored. Dispatches to the appropriate installer for the host.
#
# Dispatch precedence:
#   1. LNK_HOST env var -- explicit override (e.g. LNK_HOST=nosudo for
#      headless / no-sudo hosts). Currently the only recognized value is
#      "nosudo"; unknown values fall through to the OS default with a
#      warning so a typo doesn't silently route to the wrong installer.
#   2. Auto-detect on Linux: if `sudo -n true` fails (no passwordless
#      sudo, or no sudo entry at all), assume we're on a no-sudo host
#      and route to installers/nosudo/install.sh. This is the right call for
#      shared dev boxes, containers, and CI runners.
#   3. OS default (uname -s):
#        Darwin -> installers/macos/bootstrap_finish.sh
#        Linux  -> installers/linux/install.sh
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

dispatch_linux() {
  # Honor explicit LNK_HOST first -- predictable for re-runs and CI.
  case "${LNK_HOST:-}" in
    nosudo)
      exec bash "${REPO_DIR}/installers/nosudo/install.sh"
      ;;
    "")
      ;;
    *)
      echo "bootstrap.sh: unknown LNK_HOST='${LNK_HOST}' -- ignoring, using OS default" >&2
      ;;
  esac

  # Auto-detect: no passwordless sudo => assume nosudo host. `sudo -n true`
  # exits non-zero either because sudo isn't installed at all or because
  # the password prompt would fire -- both indicate we can't run the
  # standard install.sh (which sudos repeatedly without prompting).
  if ! command -v sudo >/dev/null 2>&1 || ! sudo -n true 2>/dev/null; then
    echo "bootstrap.sh: passwordless sudo unavailable -- routing to installers/nosudo/install.sh" >&2
    echo "bootstrap.sh: (override with LNK_HOST= or pre-cache sudo creds to take the standard path)" >&2
    exec bash "${REPO_DIR}/installers/nosudo/install.sh"
  fi

  exec bash "${REPO_DIR}/installers/linux/install.sh"
}

case "$(uname -s)" in
  Darwin)
    exec bash "${REPO_DIR}/installers/macos/bootstrap_finish.sh"
    ;;
  Linux)
    dispatch_linux
    ;;
  *)
    echo "bootstrap.sh: unsupported OS '$(uname -s)'" >&2
    exit 1
    ;;
esac
