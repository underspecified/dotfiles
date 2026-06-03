#!/usr/bin/env bash
# Usage:
#   ssh_keys.sh                       # pull from 1Password via `op` (default)
#   ssh_keys.sh --from-file PATH      # install from a local key file
#   ssh_keys.sh --from-file -         # install from stdin
#   ssh_keys.sh --vault NAME          # override 1Password vault (default: Personal)
#   ssh_keys.sh --item ITEM           # override 1Password item (default: ssh-<host>)
#
# Installs a per-host SSH private key at ~/.ssh/id_<host> (mode 600),
# derives the matching .pub via `ssh-keygen -y` (mode 644), and registers
# the key with `keychain` so subsequent shells pick it up via the `eval`
# block in zshrc.linux.
#
# Two modes — same downstream wiring:
#
#   op mode (default)
#     Requires `op` on PATH and a signed-in session (`op signin` first).
#     Reads `op://<vault>/<item>/private key` and writes it to the target.
#
#   --from-file mode
#     For air-gapped boxes that can't reach 1Password. Stage the key on
#     disk (USB, scp from another host, etc.) or pipe it via stdin, then
#     run with --from-file. No `op` dependency.
#
# Idempotent: if the target key already exists, skips re-writing. The
# .pub is re-derived if missing and the key is re-registered with
# keychain unconditionally.
#
# Output: JSON to stdout describing what was done. Diagnostics on stderr.
set -uo pipefail

# shellcheck source=SCRIPTDIR/../lib.sh
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/../lib.sh"

VAULT="Personal"
ITEM=""
FROM_FILE=""

usage() {
  sed -n '2,/^$/p' "$0" | sed 's/^# \{0,1\}//' >&2
  exit "${1:-2}"
}

parse_args() {
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --from-file)
        [[ $# -ge 2 ]] || die "--from-file requires a path or '-'"
        FROM_FILE="$2"
        shift 2
        ;;
      --vault)
        [[ $# -ge 2 ]] || die "--vault requires a name"
        VAULT="$2"
        shift 2
        ;;
      --item)
        [[ $# -ge 2 ]] || die "--item requires a name"
        ITEM="$2"
        shift 2
        ;;
      -h|--help)
        usage 0
        ;;
      *)
        die "unknown argument: $1"
        ;;
    esac
  done
}

pull_from_op() {
  local key="$1" item="$2" ref
  command -v op >/dev/null 2>&1 || die "op (1Password CLI) not on PATH"
  if ! op whoami >/dev/null 2>&1; then
    die "op is not signed in; run \`op signin\` first"
  fi
  ref="op://${VAULT}/${item}/private key"
  log "fetching ${ref}"
  # `op read` writes the secret to stdout; redirect with restrictive umask.
  ( umask 077 && op read "${ref}" > "${key}" )
  [[ -s "${key}" ]] || die "op read returned empty content for ${ref}"
}

install_from_file() {
  local src="$1" dest="$2"
  if [[ "${src}" == "-" ]]; then
    log "reading key bytes from stdin"
    ( umask 077 && cat > "${dest}" )
  else
    [[ -f "${src}" ]] || die "source file not found: ${src}"
    install -m 600 "${src}" "${dest}"
  fi
  [[ -s "${dest}" ]] || die "installed key is empty: ${dest}"
}

derive_pub() {
  local key="$1" pub="${1}.pub"
  if [[ -f "${pub}" ]]; then
    log "public key already present: ${pub}"
    return 0
  fi
  log "deriving public key: ${pub}"
  ssh-keygen -y -f "${key}" > "${pub}"
  chmod 644 "${pub}"
}

register_with_keychain() {
  local key="$1"
  command -v keychain >/dev/null 2>&1 \
    || die "keychain not on PATH (install via installers/linux/install.sh or installers/all/install_keychain_user.sh)"
  log "registering ${key} with keychain"
  keychain --quiet --agents ssh "${key}"
}

main() {
  parse_args "$@"

  local host key
  host="$(hostname -s)"
  [[ -n "${host}" ]] || die "hostname -s returned empty"
  key="${HOME}/.ssh/id_${host}"
  : "${ITEM:=ssh-${host}}"

  mkdir -p "${HOME}/.ssh"
  chmod 700 "${HOME}/.ssh"

  local mode="op" wrote_key="false"
  if [[ -n "${FROM_FILE}" ]]; then
    mode="from-file"
  fi

  if [[ -f "${key}" ]]; then
    log "key already present: ${key} (skipping write)"
  else
    if [[ "${mode}" == "from-file" ]]; then
      install_from_file "${FROM_FILE}" "${key}"
    else
      pull_from_op "${key}" "${ITEM}"
    fi
    chmod 600 "${key}"
    wrote_key="true"
  fi

  derive_pub "${key}"
  register_with_keychain "${key}"

  printf '{"host":"%s","key":"%s","pub":"%s","mode":"%s","wrote_key":%s,"vault":"%s","item":"%s"}\n' \
    "${host}" "${key}" "${key}.pub" "${mode}" "${wrote_key}" "${VAULT}" "${ITEM}"
}

main "$@"
