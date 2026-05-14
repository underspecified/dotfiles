#!/usr/bin/env bash
# Usage: git-allowed-signers-regen.sh [identity-file] [allowed-signers-file]
#
# Regenerate the SSH allowed_signers file from a git identity.conf,
# making identity.conf the single source of truth for both the signing
# side (user.signingkey) and the verification side (allowed_signers).
#
# The output file is a derived artifact -- never edit it by hand.
# Rerun this script after editing identity.conf instead.
#
# Defaults:
#   identity-file        ~/.config/git/identity.conf
#   allowed-signers-file ~/.config/git/allowed_signers
set -euo pipefail

identity_file="${1:-${HOME}/.config/git/identity.conf}"
out_file="${2:-${HOME}/.config/git/allowed_signers}"

log() { printf '\033[1;34m==>\033[0m %s\n' "$*"; }
die() { printf '\033[1;31mxx\033[0m %s\n' "$*" >&2; exit 1; }

[[ -r "${identity_file}" ]] \
  || die "cannot read identity file: ${identity_file}"

email="$(git config --file "${identity_file}" user.email || true)"
key="$(git config --file "${identity_file}" user.signingkey || true)"

[[ -n "${email}" ]] || die "no user.email in ${identity_file}"
[[ -n "${key}"   ]] || die "no user.signingkey in ${identity_file}"

# If signingkey is a path rather than a literal public key, read the .pub
# file alongside it. (Git accepts both forms; allowed_signers needs the
# literal key bytes.)
if [[ "${key}" == /* || "${key}" == "~"* ]]; then
  pub_file="${key/#\~/${HOME}}"
  [[ "${pub_file}" == *.pub ]] || pub_file="${pub_file}.pub"
  [[ -r "${pub_file}" ]] \
    || die "signingkey points at unreadable file: ${pub_file}"
  key="$(<"${pub_file}")"
fi

mkdir -p "$(dirname "${out_file}")"
printf '%s %s\n' "${email}" "${key}" > "${out_file}"
chmod 600 "${out_file}"

log "regenerated ${out_file} for ${email}"
