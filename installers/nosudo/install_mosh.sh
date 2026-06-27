#!/usr/bin/env bash
# Usage: install_mosh.sh
#
# Build mosh from source into ~/.local for the no-sudo / headless path, so a
# roaming/sleeping client (e.g. the laptop) can hold a drop-proof interactive
# session to this box. Pairs with the ssh keepalive hardening +
# `mosh <host> -- tmux new -A -s main`. Only mosh-server is strictly needed
# here (the client runs on the laptop and launches mosh-server over ssh);
# mosh + mosh-client are installed too so the box can also act as a client.
# ~/.local/bin is on PATH for `ssh <host> mosh-server` (ensure_bashrc_path).
#
# Same from-source philosophy as install_autossh.sh — NO conda / no parallel
# package manager. mosh's one hard build dep is protobuf, which no-sudo boxes
# lack (dgx02: protoc/libprotobuf absent; ncurses/openssl/zlib present). So we
# build protobuf FIRST, STATIC (--disable-shared), into the same prefix; mosh
# then links libprotobuf statically and depends only on the system
# ncurses/openssl/zlib at runtime — i.e. mosh-server is self-contained for
# protobuf with no LD_LIBRARY_PATH needed.
#
# Idempotent: skips when ~/.local/bin/mosh-server already reports MOSH_VERSION;
# skips the protobuf build when ~/.local/bin/protoc already reports its version.
#
# Env overrides:
#   MOSH_VERSION       -- mosh release (default: 1.4.0, matches the brew client)
#   PROTOBUF_VERSION   -- protobuf C++ release (default: 3.21.12 — last of the
#                         autotools `./configure` line, no abseil/cmake needed)
#   PREFIX             -- install prefix (default: $HOME/.local)
#   MOSH_SHA256 / PROTOBUF_SHA256 -- expected tarball sha256 (empty = skip+warn)
set -euo pipefail

# shellcheck source=SCRIPTDIR/../lib.sh
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/../lib.sh"

MOSH_VERSION="${MOSH_VERSION:-1.4.0}"
PROTOBUF_VERSION="${PROTOBUF_VERSION:-3.21.12}"
PREFIX="${PREFIX:-${HOME}/.local}"
MOSH_SHA256="${MOSH_SHA256:-}"
PROTOBUF_SHA256="${PROTOBUF_SHA256:-}"

DEST="${PREFIX}/bin/mosh-server"
PROTOC="${PREFIX}/bin/protoc"
URL_MOSH="https://github.com/mobile-shell/mosh/releases/download/mosh-${MOSH_VERSION}/mosh-${MOSH_VERSION}.tar.gz"
# protobuf 21.x dropped the "3." from its release TAG (v21.12) but kept it in
# the C++ asset filename (protobuf-cpp-3.21.12.tar.gz). Derive the tag.
URL_PROTOBUF="https://github.com/protocolbuffers/protobuf/releases/download/v${PROTOBUF_VERSION#3.}/protobuf-cpp-${PROTOBUF_VERSION}.tar.gz"

NPROC="$( (nproc 2>/dev/null) || echo 2)"

already_installed() {
  [[ -x "${DEST}" ]] || return 1
  "${DEST}" --version 2>&1 | grep -qF "mosh ${MOSH_VERSION}"
}

protobuf_present() {
  [[ -x "${PROTOC}" ]] || return 1
  "${PROTOC}" --version 2>&1 | grep -qF "${PROTOBUF_VERSION}"
}

verify_sha() {
  local file="$1" want="$2"
  if [[ -z "${want}" ]]; then
    warn "no sha256 pinned for $(basename "${file}"); skipping integrity check"
    return 0
  fi
  command -v sha256sum >/dev/null 2>&1 || { warn "sha256sum absent; skipping check"; return 0; }
  local got
  got="$(sha256sum "${file}" | awk '{print $1}')"
  [[ "${got}" == "${want}" ]] || die "sha256 mismatch for $(basename "${file}"): got ${got}, expected ${want}"
  log "sha256 verified: $(basename "${file}")"
}

build_protobuf() {
  local tmp="$1"
  log "downloading protobuf ${PROTOBUF_VERSION}"
  curl -fsSL "${URL_PROTOBUF}" -o "${tmp}/protobuf.tar.gz" || die "protobuf download failed: ${URL_PROTOBUF}"
  verify_sha "${tmp}/protobuf.tar.gz" "${PROTOBUF_SHA256}"
  tar -xzf "${tmp}/protobuf.tar.gz" -C "${tmp}"
  local src="${tmp}/protobuf-${PROTOBUF_VERSION}"
  [[ -d "${src}" ]] || die "unexpected protobuf tarball layout (no ${src})"
  log "building protobuf (static, -j${NPROC}) — a few minutes"
  (
    cd "${src}"
    ./configure --prefix="${PREFIX}" --disable-shared --with-pic >/dev/null
    make -j"${NPROC}" >/dev/null
    make install >/dev/null
  ) || die "protobuf build failed"
  log "protobuf installed: $("${PROTOC}" --version 2>&1)"
}

build_mosh() {
  local tmp="$1"
  log "downloading mosh ${MOSH_VERSION}"
  curl -fsSL "${URL_MOSH}" -o "${tmp}/mosh.tar.gz" || die "mosh download failed: ${URL_MOSH}"
  verify_sha "${tmp}/mosh.tar.gz" "${MOSH_SHA256}"
  tar -xzf "${tmp}/mosh.tar.gz" -C "${tmp}"
  local src="${tmp}/mosh-${MOSH_VERSION}"
  [[ -d "${src}" ]] || die "unexpected mosh tarball layout (no ${src})"
  log "building mosh (-j${NPROC})"
  (
    cd "${src}"
    # Point at our prefix: protoc on PATH, protobuf headers/lib + .pc for the
    # configure probe. System ncurses/openssl/zlib are found via default paths.
    export PATH="${PREFIX}/bin:${PATH}"
    export PKG_CONFIG_PATH="${PREFIX}/lib/pkgconfig:${PKG_CONFIG_PATH:-}"
    export CPPFLAGS="-I${PREFIX}/include ${CPPFLAGS:-}"
    export LDFLAGS="-L${PREFIX}/lib ${LDFLAGS:-}"
    ./configure --prefix="${PREFIX}" >/dev/null
    make -j"${NPROC}" >/dev/null
    make install >/dev/null
  ) || die "mosh build failed"
}

main() {
  command -v make >/dev/null 2>&1 || die "make is required"
  command -v g++ >/dev/null 2>&1 || command -v c++ >/dev/null 2>&1 || die "a C++ compiler (g++/c++) is required"
  command -v curl >/dev/null 2>&1 || die "curl is required"
  command -v pkg-config >/dev/null 2>&1 || die "pkg-config is required"

  if already_installed; then
    log "mosh-server ${MOSH_VERSION} already at ${DEST}, skipping"
    return 0
  fi

  mkdir -p "${PREFIX}/bin"
  local tmp
  tmp="$(mktemp -d)"
  # shellcheck disable=SC2064  # expand $tmp now, not on signal
  trap "rm -rf '${tmp}'" EXIT

  if protobuf_present; then
    log "protobuf ${PROTOBUF_VERSION} already at ${PROTOC}, reusing"
  else
    build_protobuf "${tmp}"
  fi

  build_mosh "${tmp}"

  already_installed || die "post-install check failed: ${DEST} does not report mosh ${MOSH_VERSION}"
  log "installed: ${DEST} ($("${DEST}" --version 2>&1 | head -1))"
}

main "$@"
