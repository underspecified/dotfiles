#!/usr/bin/env bash
# Auto-run by `lnk init -r <url>` after the repo is cloned and symlinks
# are restored. Dispatches to the appropriate installer for the host OS.
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

case "$(uname -s)" in
  Darwin)
    exec bash "${REPO_DIR}/installers/macos/bootstrap_finish.sh"
    ;;
  Linux)
    exec bash "${REPO_DIR}/installers/linux/install.sh"
    ;;
  *)
    echo "bootstrap.sh: unsupported OS '$(uname -s)'" >&2
    exit 1
    ;;
esac
