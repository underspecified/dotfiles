#!/usr/bin/env bash
# Re-run = no-op once typora is installed. The trusted-key file is
# overwritten idempotently via `tee >`; the repo line is added only when
# the .list file doesn't already mention typora.io.
set -euo pipefail

# shellcheck source=SCRIPTDIR/../lib.sh
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/../lib.sh"

if dpkg -s typora >/dev/null 2>&1; then
  log "typora already installed; skipping repo + key setup"
  exit 0
fi

### Install Typora
# Trust file written with `tee >` (truncating) -- idempotent.
wget -qO- https://typoraio.cn/linux/public-key.asc | sudo tee /etc/apt/trusted.gpg.d/typora.asc > /dev/null

# Add Typora's repository only if not already present.
if ! grep -qF "typora.io/linux" /etc/apt/sources.list.d/*.list /etc/apt/sources.list 2>/dev/null; then
  sudo add-apt-repository -y 'deb https://typora.io/linux ./'
fi

sudo apt-get update
sudo apt-get install -y typora
