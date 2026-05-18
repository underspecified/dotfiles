#!/usr/bin/env bash
# Shared idempotency helpers for installers/. Source from each installer:
#   # shellcheck source=../lib.sh
#   source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/../lib.sh"
#
# Helpers are pure-bash + standard CLI tools. Callers are expected to
# `set -euo pipefail` themselves; nothing here changes shell options.

# --- logging --------------------------------------------------------------

log()  { printf '\033[1;34m==>\033[0m %s\n' "$*"; }
warn() { printf '\033[1;33m!!\033[0m %s\n' "$*" >&2; }
die()  { printf '\033[1;31mxx\033[0m %s\n' "$*" >&2; exit 1; }

# --- clone_or_pull <url> <dest> -------------------------------------------
#
# Idempotent git clone or fast-forward pull. Prints exactly one of these
# states on stdout (and nothing else):
#
#   cloned                     - <dest> did not exist; cloned from <url>
#   updated:<before>..<after>  - HEAD moved due to ff pull
#   unchanged                  - repo present and HEAD did not move
#   skipped:dirty              - working tree dirty, no pull attempted
#   skipped:detached           - detached HEAD, no pull attempted
#   skipped:diverged           - ff pull rejected (history diverged)
#
# Callers gate downstream work on the state, e.g.:
#   state="$(clone_or_pull "$URL" "$DIR")"
#   [[ "$state" == cloned || "$state" == updated:* ]] && rebuild
#
# Exit 0 in all cases above. Hard git errors (e.g. clone over the network)
# propagate via set -e in the calling script.
clone_or_pull() {
  local url="$1" dest="$2"

  if [[ ! -d "${dest}/.git" ]]; then
    mkdir -p "$(dirname "${dest}")"
    git clone --quiet "${url}" "${dest}"
    echo "cloned"
    return 0
  fi

  if [[ -n "$(git -C "${dest}" status --porcelain)" ]]; then
    echo "skipped:dirty"
    return 0
  fi

  if ! git -C "${dest}" symbolic-ref --quiet HEAD >/dev/null; then
    echo "skipped:detached"
    return 0
  fi

  local before after
  before="$(git -C "${dest}" rev-parse HEAD)"
  if ! git -C "${dest}" pull --ff-only --quiet; then
    echo "skipped:diverged"
    return 0
  fi
  after="$(git -C "${dest}" rev-parse HEAD)"

  if [[ "${before}" == "${after}" ]]; then
    echo "unchanged"
  else
    echo "updated:${before:0:7}..${after:0:7}"
  fi
}

# --- symlink_force <target> <link> ----------------------------------------
#
# `ln -sfn` wrapper: clobbers any existing symlink (or dir-symlink) and
# repoints <link> at <target>. Use when the symlink should always reflect
# the canonical target, regardless of prior state.
symlink_force() {
  local target="$1" link="$2"
  ln -sfn "${target}" "${link}"
}

# --- apt_ensure_repo <list_path> <list_line> <key_url> <keyring_path> -----
#
# Idempotent apt source setup using the modern signed-by + keyring pattern
# (avoids the deprecated apt-key). Writes the dearmored keyring only if
# missing, and writes the .list file only if the desired line is not
# already present. Does NOT call `apt update` -- the caller batches that
# once after all repos are ensured.
apt_ensure_repo() {
  local list_path="$1" list_line="$2" key_url="$3" keyring_path="$4"

  if [[ ! -f "${keyring_path}" ]]; then
    sudo mkdir -p "$(dirname "${keyring_path}")"
    wget -qO- "${key_url}" | sudo gpg --dearmor -o "${keyring_path}"
    sudo chmod go+r "${keyring_path}"
  fi

  if [[ ! -f "${list_path}" ]] || ! grep -qF "${list_line}" "${list_path}"; then
    echo "${list_line}" | sudo tee "${list_path}" > /dev/null
  fi
}
