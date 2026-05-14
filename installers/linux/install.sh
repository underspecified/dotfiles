#!/usr/bin/env bash
# Usage: install.sh
# Bootstraps a fresh Ubuntu desktop into the i3 stack used by this repo.
# Auto-invoked by ../bootstrap.sh after `lnk init -r` lays down symlinks.
set -euo pipefail

CUR_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

### baseline apt deps
# Trimmed:
#   golang  -> installed by install_darkman.sh from source build
#   psensor -> installed by install_profilers.sh
#   emacs, keychain, chrome-gnome-shell -> unused (1Password SSH agent
#     supersedes keychain; no GNOME-Chrome shell extension flow here)
install_apt() {
  sudo apt update
  sudo apt install -y curl git jq nodejs npm openssh-server shellcheck trash-cli xsel zsh
}

install_google_chrome() {
  sudo sh -c 'echo "deb http://dl.google.com/linux/chrome/deb/ stable main" >> /etc/apt/sources.list.d/google.list'
  sudo wget -q -O - https://dl-ssl.google.com/linux/linux_signing_key.pub | sudo apt-key add -
  sudo apt update
  sudo apt-get install -y google-chrome-stable
}

install_gh() {
  type -p wget >/dev/null || sudo apt install -y wget
  sudo mkdir -p -m 755 /etc/apt/keyrings
  wget -qO- https://cli.github.com/packages/githubcli-archive-keyring.gpg \
    | sudo tee /etc/apt/keyrings/githubcli-archive-keyring.gpg > /dev/null
  sudo chmod go+r /etc/apt/keyrings/githubcli-archive-keyring.gpg
  echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" \
    | sudo tee /etc/apt/sources.list.d/github-cli.list > /dev/null
  sudo apt update
  sudo apt install -y gh
}

install_zed() {
  curl -f https://zed.dev/install.sh | sh
}

update_git() {
  sudo add-apt-repository -y ppa:git-core/ppa
  sudo apt update
  sudo apt install -y git
}

update_less() {
  local workdir
  workdir="$(mktemp -d)"
  trap 'rm -rf "${workdir}"' RETURN
  curl -fL https://www.greenwoodsoftware.com/less/less-668.tar.gz \
    | tar -xzf - -C "${workdir}"
  (cd "${workdir}/less-668" && ./configure --prefix="${HOME}/.local" && make install)
}

install_apt
install_gh
install_google_chrome
install_zed
update_git
update_less

bash "${CUR_DIR}/install_uv.sh"
bash "${CUR_DIR}/install_fonts.sh"
bash "${CUR_DIR}/install_1password.sh"
bash "${CUR_DIR}/install_darkman.sh"
bash "${CUR_DIR}/install_i3.sh"
bash "${CUR_DIR}/install_kitty.sh"
bash "${CUR_DIR}/install_nvidia_drivers.sh"
bash "${CUR_DIR}/install_profilers.sh"
bash "${CUR_DIR}/install_usb_autosuspend.sh"

# Final step: select display profile and generate i3/dunst/Xresources/kitty
# configs. Interactive prompt unless a profile name was passed via env.
bash "${CUR_DIR}/setup_display.sh" "${DISPLAY_PROFILE:-}"
