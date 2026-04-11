#!/usr/bin/env bash
# Usage: op-config-pull.sh <op-item-title> <local-file> [vault]
#
# Download the notesPlain field of a 1Password Secure Note and write
# it to a local file. Creates the parent directory if missing and
# sets mode 600 on the result.
#
# Requires: 1Password CLI (`op`) signed in and the item accessible.
#
# Examples:
#   op-config-pull.sh ssh-config-honda ~/.ssh/config.d/work-honda
#   op-config-pull.sh gitconfig-work   ~/.gitconfig
set -euo pipefail

log() { printf '\033[1;34m==>\033[0m %s\n' "$*"; }
die() { printf '\033[1;31mxx\033[0m %s\n' "$*" >&2; exit 1; }

[[ $# -ge 2 && $# -le 3 ]] \
  || die "usage: $0 <op-item-title> <local-file> [vault]"

item_title="$1"
local_file="$2"
vault="${3:-Personal}"

command -v op >/dev/null 2>&1 || die "1Password CLI (op) not found in PATH"

mkdir -p "$(dirname "${local_file}")"

# `op read` uses the secret reference format; notesPlain is a first-class
# field on Secure Notes and returns the raw note text.
op read "op://${vault}/${item_title}/notesPlain" > "${local_file}"
chmod 600 "${local_file}"

log "op://${vault}/${item_title} → ${local_file}"
