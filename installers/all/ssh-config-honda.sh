#!/usr/bin/env bash
# Usage: bash ~/.config/lnk/installers/all/ssh-config-honda.sh
#
# Pull the Honda internal-hosts SSH snippet from 1Password into
# ~/.ssh/config.d/honda, where it is picked up by the
# `Include ~/.ssh/config.d/*` directive in the main ssh config.
#
# Purpose: pin Host -> IP for internal machines whose DNS isn't
# universally resolvable (e.g. work-LAN FQDNs not visible from home,
# from cafes, or from Tailscale-subnet-routed peers that have no
# work-LAN DNS server). The internal IPs live in 1Password so they
# stay out of the public dotfiles mirror.
#
# Stored as a 1Password DOCUMENT (not a Secure Note), so this uses
# `op document get` directly rather than going through
# op-config-pull.sh (which reads the notesPlain field of Secure Notes).
#
# Requires: 1Password CLI (`op`) signed in.
#
# Idempotent -- safe to rerun.
set -euo pipefail

log() { printf '\033[1;34m==>\033[0m %s\n' "$*"; }
die() { printf '\033[1;31mxx\033[0m %s\n' "$*" >&2; exit 1; }

ITEM="ssh-config-honda"
DEST="${HOME}/.ssh/config.d/honda"

command -v op >/dev/null 2>&1 || die "1Password CLI (op) not found in PATH"
op whoami >/dev/null 2>&1 || die "op not signed in; run \`eval \"\$(op signin)\"\` first"

mkdir -p "$(dirname "${DEST}")"

# Write to a temp file and rename on success so a failed `op document get`
# doesn't clobber an existing valid file with an empty one.
tmp_file="$(mktemp "${DEST}.XXXXXX")"
trap 'rm -f "${tmp_file}"' EXIT
op document get "${ITEM}" --out-file "${tmp_file}" --force
chmod 600 "${tmp_file}"
mv "${tmp_file}" "${DEST}"
trap - EXIT

log "${ITEM} -> ${DEST}"
