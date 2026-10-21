#!/usr/bin/env bash
# Usage: setup-signing.sh [keychain]   (default: the login keychain)
# Output: one status line on stdout
# One-time setup on the Mac that rebuilds menubar-tint-notify: creates the
# self-signed code-signing identity "menubar-tint-notify" in the keychain and
# lets /usr/bin/codesign use its key without a dialog. Rebuilds signed with it
# keep one designated requirement, so they keep Screen Recording. Idempotent:
# exits 0 if the identity exists. The key and certificate exist outside the
# keychain only in a temp dir that is deleted on exit; nothing is written here
# (this repo is public).
set -uo pipefail

name="menubar-tint-notify"

die() {
  echo "error: $*" >&2
  exit 1
}

# Runs a command with stderr captured, and shows that only if it fails.
quiet() {
  "$@" 2>"${tmp}/stderr" || {
    cat "${tmp}/stderr" >&2
    return 1
  }
}

main() {
  local keychain="${1:-${HOME}/Library/Keychains/login.keychain-db}"
  [[ -f "${keychain}" ]] || die "no keychain at ${keychain}"
  # Captured before matching: grep -q under pipefail could fail on SIGPIPE and
  # import a second identity of the same name, which makes codesign -s ambiguous.
  local identities
  identities="$(security find-identity -p codesigning "${keychain}")" || die "security find-identity failed"
  if [[ "${identities}" == *"\"${name}\""* ]]; then
    echo "identity ${name} already in ${keychain}"
    exit 0
  fi

  umask 077
  tmp="$(mktemp -d)" || die "mktemp failed"
  trap 'rm -rf "${tmp}"' EXIT

  cat >"${tmp}/req.cnf" <<EOF
[req]
distinguished_name = dn
x509_extensions = ext
prompt = no
[dn]
CN = ${name}
[ext]
basicConstraints = critical, CA:FALSE
keyUsage = critical, digitalSignature
extendedKeyUsage = critical, codeSigning
subjectKeyIdentifier = hash
EOF

  # macOS's own LibreSSL, not whatever openssl is first in PATH: its p12
  # encryption is the one `security import` reads everywhere. The p12 password
  # only protects the file for the few seconds it exists.
  local openssl=/usr/bin/openssl pass
  pass="$("${openssl}" rand -hex 16)" || die "openssl rand failed"
  quiet "${openssl}" req -x509 -newkey rsa:2048 -nodes -days 7300 -config "${tmp}/req.cnf" \
    -keyout "${tmp}/key.pem" -out "${tmp}/cert.pem" ||
    die "openssl req failed"
  quiet "${openssl}" pkcs12 -export -name "${name}" -inkey "${tmp}/key.pem" -in "${tmp}/cert.pem" \
    -out "${tmp}/id.p12" -passout "pass:${pass}" ||
    die "openssl pkcs12 failed"
  # -T puts codesign on the key's access list, so signing needs no dialog.
  security import "${tmp}/id.p12" -k "${keychain}" -f pkcs12 -P "${pass}" -T /usr/bin/codesign >/dev/null ||
    die "security import failed"

  echo "created identity ${name} in ${keychain}"
}

main "$@"
