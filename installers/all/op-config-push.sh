#!/usr/bin/env bash
# Usage: op-config-push.sh <local-file> <op-item-title> [vault]
#
# Upload the contents of a local file into a 1Password Secure Note.
# If an item with <op-item-title> already exists in <vault>, its
# notesPlain field is updated; otherwise a new Secure Note is created.
#
# Requires: 1Password CLI (`op`) signed in, vault writable.
#
# Examples:
#   op-config-push.sh ~/.ssh/config.d/work-honda ssh-config-honda
#   op-config-push.sh ~/.gitconfig.work          gitconfig-work
#   op-config-push.sh ~/.gitconfig.personal      gitconfig-personal  Private
set -euo pipefail

log() { printf '\033[1;34m==>\033[0m %s\n' "$*"; }
die() { printf '\033[1;31mxx\033[0m %s\n' "$*" >&2; exit 1; }

[[ $# -ge 2 && $# -le 3 ]] \
  || die "usage: $0 <local-file> <op-item-title> [vault]"

local_file="$1"
item_title="$2"
vault="${3:-Personal}"

[[ -r "${local_file}" ]] || die "cannot read file: ${local_file}"
command -v op >/dev/null 2>&1 || die "1Password CLI (op) not found in PATH"

# Read file content; pass as a single assignment. `op` handles multiline
# argv fine, but the shell must quote "${content}" literally to preserve
# newlines and special characters.
content="$(<"${local_file}")"

if op item get "${item_title}" --vault "${vault}" >/dev/null 2>&1; then
  log "updating existing Secure Note: ${item_title}"
  op item edit "${item_title}" --vault "${vault}" \
    "notesPlain=${content}" >/dev/null
else
  log "creating new Secure Note: ${item_title}"
  op item create --category "Secure Note" \
    --title "${item_title}" \
    --vault "${vault}" \
    "notesPlain=${content}" >/dev/null
fi

log "op://${vault}/${item_title} ← ${local_file}"
