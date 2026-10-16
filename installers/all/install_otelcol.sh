#!/usr/bin/env bash
# Usage: bash ~/.config/lnk/installers/all/install_otelcol.sh
#
# Pinned OpenTelemetry Collector (core `otelcol`) as a user service that takes
# Claude Code metrics on 127.0.0.1:${PORT} and writes ~/.local/state/otelcol/
# metrics.jsonl (see otelcol/config.yaml). macOS: LaunchAgent com.eric.otelcol.
# Linux: systemd --user otelcol.service. No sudo. Idempotent: a re-run with
# everything current downloads, writes and restarts nothing.
#
# Offline host: copy otelcol_<VERSION>_<platform>.tar.gz into ~/.cache/otelcol/
# from a host that has it, then re-run; the sha256 check still applies.
set -uo pipefail

# shellcheck source=SCRIPTDIR/../lib.sh
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/../lib.sh"

VERSION="0.162.0"
PORT=24318 # also in otelcol/config.yaml and .claude/settings.json
URL="https://github.com/open-telemetry/opentelemetry-collector-releases/releases/download"
SRC_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/otelcol"
BIN="${HOME}/.local/bin/otelcol"
CACHE="${HOME}/.cache/otelcol"
STATE="${HOME}/.local/state/otelcol"
LABEL="com.eric.otelcol"
changed=0
work="$(mktemp -d)" || die "mktemp failed"
trap 'rm -rf "${work}"' EXIT

# Sets the caller's plat + sum (GitHub release asset digests for VERSION).
# Called directly, never in $(...), so die stops the script.
platform() {
  case "$(uname -s)_$(uname -m)" in
  Darwin_arm64) plat=darwin_arm64 sum=53de34c02913f54aa240861e0febf67a6839bc8ecf1bfab83a8ae7d355d30674 ;;
  Linux_x86_64) plat=linux_amd64 sum=f99929987a915d3c6b2c9b15bc4938c5cea903a37a3f49e478024a0fa0772339 ;;
  Linux_aarch64) plat=linux_arm64 sum=6ae44683515ae0e561acbc9f2a0152dc98ef14ce89035417f95184cffd7cca12 ;;
  *) die "unsupported platform: $(uname -sm)" ;;
  esac
}

sha256_of() {
  if command -v sha256sum >/dev/null 2>&1; then sha256sum "$1"; else shasum -a 256 "$1"; fi | awk '{print $1}'
}

# put <src> <dest>: replace dest via temp + mv (new inode, safe while running)
# only when its content differs.
put() {
  if cmp -s "$1" "$2"; then
    log "unchanged: $2"
    return 0
  fi
  mkdir -p "$(dirname "$2")" || die "cannot create $(dirname "$2")"
  cp "$1" "$2.tmp" || die "cannot write $2.tmp"
  mv -f "$2.tmp" "$2" || die "cannot replace $2"
  log "installed: $2"
  changed=1
}

install_binary() {
  if [[ "$("${BIN}" --version 2>/dev/null)" == *" ${VERSION}" ]]; then
    log "unchanged: ${BIN} ${VERSION}"
    return 0
  fi
  local plat="" sum="" tgz old
  platform
  tgz="${CACHE}/otelcol_${VERSION}_${plat}.tar.gz"
  mkdir -p "${CACHE}" || die "cannot create ${CACHE}"
  if [[ ! -f "${tgz}" ]]; then
    log "downloading otelcol ${VERSION} (${plat})"
    curl -fsSL --connect-timeout 10 --max-time 300 -o "${tgz}.part" \
      "${URL}/v${VERSION}/otelcol_${VERSION}_${plat}.tar.gz" || die "download failed: ${URL}"
    # Verify before caching: a 200 with the wrong body must not poison the cache.
    if [[ "$(sha256_of "${tgz}.part")" != "${sum}" ]]; then
      rm -f "${tgz}.part"
      die "sha256 mismatch on download of ${tgz}"
    fi
    mv -f "${tgz}.part" "${tgz}" || die "cannot write ${tgz}"
  fi
  [[ "$(sha256_of "${tgz}")" == "${sum}" ]] || die "sha256 mismatch: ${tgz} (delete it and re-run)"
  tar -xzf "${tgz}" -C "${work}" otelcol || die "cannot extract ${tgz}"
  put "${work}/otelcol" "${BIN}"
  # Keep this version's tarball (it seeds offline hosts); drop older ones.
  for old in "${CACHE}"/otelcol_*.tar.gz; do
    if [[ -e "${old}" && "${old}" != "${tgz}" ]]; then
      rm -f "${old}" && log "removed: ${old}"
    fi
  done
}

service_macos() {
  local plist="${HOME}/Library/LaunchAgents/${LABEL}.plist" domain
  domain="gui/$(id -u)"
  sed "s|@HOME@|${HOME}|g" "${SRC_DIR}/${LABEL}.plist" >"${work}/plist" || die "cannot render the plist"
  put "${work}/plist" "${plist}"
  if launchctl print "${domain}/${LABEL}" >/dev/null 2>&1; then
    ((changed)) || return 0
    log "restarting ${LABEL}"
    launchctl bootout "${domain}/${LABEL}"
    # bootout returns before the job is gone; bootstrap would then fail.
    for _ in 1 2 3 4 5 6 7 8 9 10; do
      launchctl print "${domain}/${LABEL}" >/dev/null 2>&1 || break
      sleep 0.5
    done
  fi
  launchctl bootstrap "${domain}" "${plist}" || die "launchctl bootstrap ${plist} failed"
}

service_linux() {
  if ! systemctl --user show-environment >/dev/null 2>&1; then
    warn "no systemd --user session: otelcol not started; sessions here export to whatever holds 127.0.0.1:${PORT}"
    exit 0
  fi
  put "${SRC_DIR}/otelcol.service" "${HOME}/.config/systemd/user/otelcol.service"
  if ((changed)); then
    log "restarting otelcol.service"
    systemctl --user daemon-reload || die "systemctl --user daemon-reload failed"
    systemctl --user restart otelcol.service || die "cannot restart otelcol.service"
  fi
  systemctl --user is-enabled -q otelcol.service ||
    systemctl --user enable -q otelcol.service || die "cannot enable otelcol.service"
  systemctl --user is-active -q otelcol.service ||
    systemctl --user start otelcol.service || die "cannot start otelcol.service"
  if [[ "$(loginctl show-user "$(id -un)" -p Linger --value 2>/dev/null)" != yes ]]; then
    loginctl enable-linger "$(id -un)" || warn "linger is off: otelcol stops when you log out"
  fi
}

service_pid() {
  case "$(uname -s)" in
  Darwin) launchctl print "gui/$(id -u)/${LABEL}" 2>/dev/null | awk '$1 == "pid" {print $3}' ;;
  *) systemctl --user show -p MainPID --value otelcol.service 2>/dev/null ;;
  esac
}

# True when pid $1 itself holds the 127.0.0.1:PORT listener. "Service running
# and the port answers" is not enough: another process can hold the port while
# the service crash-loops on bind.
owns_port() {
  if command -v lsof >/dev/null 2>&1; then
    lsof -nP -a -p "$1" -iTCP@127.0.0.1:"${PORT}" -sTCP:LISTEN >/dev/null 2>&1
  else
    ss -ltnp "sport = :${PORT}" 2>/dev/null | grep -q "127.0.0.1:${PORT} .*pid=$1,"
  fi
}

check_listener() {
  local pid
  for _ in 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20; do
    pid="$(service_pid)"
    if [[ -n "${pid}" && "${pid}" != 0 ]] && owns_port "${pid}"; then
      log "otelcol (pid ${pid}) is listening on 127.0.0.1:${PORT}"
      return 0
    fi
    sleep 0.5
  done
  die "otelcol is not the listener on 127.0.0.1:${PORT}: port taken? (logs: ~/Library/Logs/otelcol.log or journalctl --user -u otelcol)"
}

main() {
  install_binary
  put "${SRC_DIR}/config.yaml" "${HOME}/.config/otelcol/config.yaml"
  # Lines carry the account email and ids: owner-only. The collector creates a
  # missing dir 0700 (config.yaml) but never changes an existing one.
  mkdir -p "${STATE}" || die "cannot create ${STATE}"
  chmod 700 "${STATE}" || die "cannot chmod ${STATE}"
  case "$(uname -s)" in
  Darwin) service_macos ;;
  Linux) service_linux ;;
  *) die "unsupported OS: $(uname -s)" ;;
  esac
  check_listener
}

main "$@"
