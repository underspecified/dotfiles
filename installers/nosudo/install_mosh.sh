#!/usr/bin/env bash
# Usage: install_mosh.sh
#
# Install mosh (mainly mosh-server) into ~/.local/bin for the no-sudo /
# headless path, so a roaming/sleeping client (e.g. the laptop) can hold a
# drop-proof interactive session to this box. Pairs with the ssh keepalive
# hardening + `mosh <host> -- tmux new -A -s main`.
#
# Why micromamba/conda-forge instead of from-source (cf. install_autossh.sh):
# mosh hard-requires protobuf (+ protoc) at build time, and no-sudo boxes like
# dgx02 lack the protobuf dev headers (verified: protoc/libprotobuf absent;
# ncurses/openssl/zlib present but not enough). conda-forge ships a prebuilt,
# SELF-CONTAINED mosh (bundles its own libprotobuf in the env), so there is no
# compile and no dependency on system libprotobuf. dgx02 reaches
# conda.anaconda.org (verified 200), and github (micromamba release) over the
# same path git already uses.
#
# Only mosh-server is strictly needed here (the client runs on the laptop and
# launches mosh-server over ssh); mosh + mosh-client are symlinked too so the
# box can also act as a client. mosh-server lands in ~/.local/bin, which is on
# PATH for `ssh <host> mosh-server` (ensure_bashrc_path in install.sh).
#
# Idempotent: skips when ~/.local/bin/mosh-server already reports MOSH_VERSION.
#
# Env overrides:
#   MOSH_VERSION       -- conda-forge mosh build (default: 1.4.0, matches the
#                         brew client on macOS; keep client/server in lockstep)
#   PREFIX             -- install prefix (default: $HOME/.local)
#   MICROMAMBA_URL     -- override the micromamba release asset URL
set -euo pipefail

# shellcheck source=SCRIPTDIR/../lib.sh
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/../lib.sh"

MOSH_VERSION="${MOSH_VERSION:-1.4.0}"
PREFIX="${PREFIX:-${HOME}/.local}"
ENV_PREFIX="${PREFIX}/opt/mosh"
MM_BIN="${PREFIX}/bin/micromamba"
export MAMBA_ROOT_PREFIX="${MAMBA_ROOT_PREFIX:-${PREFIX}/share/micromamba}"

DEST="${PREFIX}/bin/mosh-server"

already_installed() {
  [[ -x "${DEST}" ]] || return 1
  "${DEST}" --version 2>&1 | grep -qF "mosh ${MOSH_VERSION}"
}

# Resolve the micromamba release asset for this CPU arch.
micromamba_url() {
  if [[ -n "${MICROMAMBA_URL:-}" ]]; then
    printf '%s' "${MICROMAMBA_URL}"
    return 0
  fi
  local arch
  case "$(uname -m)" in
    x86_64 | amd64) arch="linux-64" ;;
    aarch64 | arm64) arch="linux-aarch64" ;;
    ppc64le) arch="linux-ppc64le" ;;
    *) die "unsupported arch for micromamba: $(uname -m)" ;;
  esac
  printf 'https://github.com/mamba-org/micromamba-releases/releases/latest/download/micromamba-%s' "${arch}"
}

# Download the standalone micromamba binary once (reused on re-runs).
ensure_micromamba() {
  if [[ -x "${MM_BIN}" ]]; then
    log "micromamba present: ${MM_BIN} ($("${MM_BIN}" --version 2>/dev/null))"
    return 0
  fi
  command -v curl >/dev/null 2>&1 || die "curl is required"
  local url
  url="$(micromamba_url)"
  mkdir -p "${PREFIX}/bin"
  log "downloading micromamba from ${url}"
  curl -fsSL "${url}" -o "${MM_BIN}" || die "micromamba download failed: ${url}"
  chmod +x "${MM_BIN}"
  log "micromamba installed: $("${MM_BIN}" --version 2>/dev/null)"
}

main() {
  if already_installed; then
    log "mosh-server ${MOSH_VERSION} already at ${DEST}, skipping"
    return 0
  fi

  ensure_micromamba

  # Create (or reuse) a self-contained env holding the prebuilt mosh.
  if [[ -x "${ENV_PREFIX}/bin/mosh-server" ]]; then
    log "reusing mosh env at ${ENV_PREFIX}"
  else
    log "creating mosh env (conda-forge mosh=${MOSH_VERSION}) at ${ENV_PREFIX}"
    "${MM_BIN}" create -y -p "${ENV_PREFIX}" -c conda-forge "mosh=${MOSH_VERSION}" \
      || die "micromamba create failed (conda-forge unreachable or no mosh=${MOSH_VERSION}?)"
  fi
  [[ -x "${ENV_PREFIX}/bin/mosh-server" ]] || die "mosh-server missing after env create"

  # Symlink into ~/.local/bin. conda binaries carry $ORIGIN/../lib RPATH, so the
  # bundled libs resolve through the symlink (symlink is resolved before $ORIGIN).
  mkdir -p "${PREFIX}/bin"
  local b
  for b in mosh-server mosh mosh-client; do
    [[ -e "${ENV_PREFIX}/bin/${b}" ]] && ln -sfn "${ENV_PREFIX}/bin/${b}" "${PREFIX}/bin/${b}"
  done

  already_installed || die "post-install check failed: ${DEST} does not report mosh ${MOSH_VERSION}"
  log "installed: ${DEST} ($("${DEST}" --version 2>&1 | head -1))"
}

main "$@"
