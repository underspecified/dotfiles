#!/usr/bin/env bash
# Usage: nvidia_powercap.sh [power_limit_watts] [clock_max_mhz]
#        nvidia_powercap.sh --reset      # restore defaults (unlock clocks, default PL)
#        nvidia_powercap.sh --show        # print current power/clock state, no changes
# Caps RTX 5090 sustained power and boost clock to stop transient-spike crashes.
# Self-elevates with sudo; run as your normal user.
# Output: human-readable status to stderr, final nvidia-smi summary to stdout.
set -uo pipefail

# Defaults chosen for a 575W-default / 3105MHz-max 5090: lock boost ~500MHz below
# the spiky ceiling and trim board power as a backstop. Override via args or env.
PL_WATTS="${1:-${NVIDIA_PL_WATTS:-500}}"
CLOCK_MAX="${2:-${NVIDIA_CLOCK_MAX:-2600}}"

die() { echo "error: $*" >&2; exit 1; }

# Re-exec under sudo if not already root, preserving args.
ensure_root() {
  if [[ "${EUID}" -ne 0 ]]; then
    echo "escalating with sudo..." >&2
    exec sudo -- "$0" "$@"
  fi
}

# Clamp requested power limit to the card's advertised [min,max] window.
clamp_power_limit() {
  local requested="$1" min max
  min="$(nvidia-smi -q -d POWER | awk -F: '/Min Power Limit/ {gsub(/[^0-9.]/,"",$2); print int($2); exit}')"
  max="$(nvidia-smi -q -d POWER | awk -F: '/Max Power Limit/ {gsub(/[^0-9.]/,"",$2); print int($2); exit}')"
  [[ -n "${min}" && -n "${max}" ]] || die "could not read power-limit range from nvidia-smi"
  if (( requested < min )); then
    echo "requested ${requested}W below floor; clamping to ${min}W" >&2
    requested="${min}"
  elif (( requested > max )); then
    echo "requested ${requested}W above ceiling; clamping to ${max}W" >&2
    requested="${max}"
  fi
  echo "${requested}"
}

show_state() {
  nvidia-smi --query-gpu=power.draw,power.limit,clocks.gr,clocks.max.gr \
    --format=csv,noheader
}

reset_caps() {
  echo "restoring default clocks and power limit..." >&2
  nvidia-smi -rgc >/dev/null || die "failed to reset clocks (-rgc)"
  # Re-apply the card's own default power limit.
  local def
  def="$(nvidia-smi -q -d POWER | awk -F: '/Default Power Limit/ {gsub(/[^0-9.]/,"",$2); print int($2); exit}')"
  [[ -n "${def}" ]] && nvidia-smi -pl "${def}" >/dev/null
  echo "reset done." >&2
  show_state
}

apply_caps() {
  local pl="$1" gc="$2"
  echo "enabling persistence mode..." >&2
  nvidia-smi -pm 1 >/dev/null || die "failed to enable persistence mode"
  echo "locking GPU clock to 0-${gc} MHz..." >&2
  nvidia-smi -lgc "0,${gc}" >/dev/null || die "failed to lock GPU clock (-lgc)"
  echo "setting power limit to ${pl}W..." >&2
  nvidia-smi -pl "${pl}" >/dev/null || die "failed to set power limit (-pl)"
  echo "applied. current state:" >&2
  show_state
}

main() {
  command -v nvidia-smi >/dev/null || die "nvidia-smi not found"

  # Read-only / help paths need no privileges.
  case "${1:-}" in
    --show)  show_state; exit 0 ;;
    -h|--help)
      grep '^# ' "$0" | sed 's/^# //'
      exit 0 ;;
  esac

  # Everything below mutates GPU state; escalate once, then re-enter as root.
  ensure_root "$@"

  if [[ "${1:-}" == "--reset" ]]; then
    reset_caps
    exit 0
  fi

  [[ "${PL_WATTS}" =~ ^[0-9]+$ ]] || die "power limit must be an integer (watts): ${PL_WATTS}"
  [[ "${CLOCK_MAX}" =~ ^[0-9]+$ ]] || die "clock max must be an integer (MHz): ${CLOCK_MAX}"

  local pl
  pl="$(clamp_power_limit "${PL_WATTS}")" || exit 1
  apply_caps "${pl}" "${CLOCK_MAX}"
}

main "$@"
