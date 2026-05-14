#!/usr/bin/env bash
# Usage: setup_git.sh [identity]
#
# Set up the git identity on this machine by pulling the chosen
# identity.conf from 1Password and regenerating allowed_signers from it.
#
# With no argument, prompts interactively. Available identities:
#   hri-jp          HRI-JP work identity        (op://Personal/git-identity-work)
#   underspecified  Personal identity           (op://Personal/git-identity-personal)
set -euo pipefail

ALL_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

log()  { printf '\033[1;34m==>\033[0m %s\n' "$*"; }
die()  { printf '\033[1;31mxx\033[0m %s\n' "$*" >&2; exit 1; }

available_identities=(hri-jp underspecified)

usage() {
  cat <<EOF
Usage: $(basename "$0") [identity]

Available identities:
  hri-jp           HRI-JP work identity
  underspecified   Personal identity

Run with no argument to pick interactively.
EOF
}

prompt_for_identity() {
  local i choice
  printf 'Select git identity:\n' >&2
  for i in "${!available_identities[@]}"; do
    printf '  %d) %s\n' "$((i + 1))" "${available_identities[i]}" >&2
  done
  printf '> ' >&2
  read -r choice
  if [[ "${choice}" =~ ^[0-9]+$ ]] \
    && (( choice >= 1 && choice <= ${#available_identities[@]} )); then
    printf '%s\n' "${available_identities[$((choice - 1))]}"
  else
    printf '%s\n' "${choice}"
  fi
}

dispatch() {
  local identity="$1"
  case "${identity}" in
    -h|--help) usage; exit 0 ;;
    hri-jp|hri_jp)
      log "setting up hri_jp (work) git identity"
      bash "${ALL_DIR}/git-identity-hri-jp.sh"
      ;;
    underspecified)
      log "setting up underspecified (personal) git identity"
      bash "${ALL_DIR}/git-identity-underspecified.sh"
      ;;
    *) die "unknown identity: ${identity} (valid: ${available_identities[*]})" ;;
  esac
}

main() {
  local identity
  if [[ $# -eq 0 ]]; then
    identity="$(prompt_for_identity)"
  elif [[ $# -eq 1 ]]; then
    identity="$1"
  else
    usage >&2
    exit 1
  fi
  dispatch "${identity}"
}

main "$@"
