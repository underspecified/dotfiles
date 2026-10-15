#!/usr/bin/env bash
# Usage: bash setup_good_night_automation.sh schedule [today] HH:MM
#
# Arms a ONE-SHOT automated /good-night on macOS for the given time today:
#   schedule today HH:MM   arm for today at HH:MM (24h)
#   schedule HH:MM         same (today implied)
#
# Sets the launchd agent's fire time (com.eric.good-night-nightly), (re)loads it
# so it fires once at HH:MM, and schedules a one-time pmset power-wake
# WAKE_OFFSET_MIN minutes earlier so a sleeping Mac is awake to fire. The agent
# unloads ITSELF after firing (see run-nightly.sh) — so this must be re-run to
# arm the next run, manually or from /good-morning. That makes good-night
# work-day-only: it runs only on days good-morning (or you) armed it.
#
# Edits the lnk-tracked plist in place (commit + push to persist across Macs).
# No sudo when a repeating wake already covers today at that time; set it once
# per Mac with `sudo pmset repeat wake MTWRF 21:55:00` (for the 22:00 default).
# Otherwise falls back to a one-time `sudo pmset schedule wake`, which needs a
# terminal for the TouchID/password prompt. Wake is honored only on AC power.
set -euo pipefail

# shellcheck source=SCRIPTDIR/../lib.sh
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/../lib.sh"

label="com.eric.good-night-nightly"
plist_link="${HOME}/Library/LaunchAgents/${label}.plist"
wake_offset_min=5
plistbuddy="/usr/libexec/PlistBuddy"

# Self-locate the lnk-tracked plist from the script's own path so PlistBuddy
# edits the repo file directly (editing through the symlink risks replacing it
# with a regular file). installers/macos -> repo root -> macos.lnk/...
script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
repo_root="$(cd "${script_dir}/../.." && pwd)"
plist_real="${repo_root}/macos.lnk/Library/LaunchAgents/${label}.plist"

usage() { die "usage: $(basename "$0") schedule [today] HH:MM"; }

# True if a repeating pmset wake fires today at H:M (24h). pmset prints it as
# e.g. "  wake at 9:55PM weekdays only" under "Repeating power events:".
repeat_wake_covers() {
  local h12=$(($1 % 12 == 0 ? 12 : $1 % 12)) ampm="AM" line
  (($1 >= 12)) && ampm="PM"
  line="$(pmset -g sched | sed -n '/^Repeating power events:/,/^[^ ]/p' |
    grep -E "^ +wake[a-z]* at $(printf '%d:%02d%s' "${h12}" "$2" "${ampm}") " || true)"
  case "${line}" in
  "") return 1 ;;
  *"every day"*) return 0 ;;
  *"weekdays only"*) (($(date +%u) <= 5)) ;;
  *"weekends only"*) (($(date +%u) >= 6)) ;;
  *) [[ "${line}" == *"$(LC_ALL=C date +%A)"* ]] ;;
  esac
}

check_preconditions() {
  [[ "$(uname -s)" == "Darwin" ]] || die "good-night automation is macOS-only"
  [[ -x "${plistbuddy}" ]] || die "PlistBuddy not found at ${plistbuddy}"
  [[ -f "${plist_real}" ]] || die "plist not found at ${plist_real} — run 'lnk pull' first"
  [[ -e "${plist_link}" ]] || die "launchd symlink missing at ${plist_link} — run 'lnk pull' first"
}

# Arm a one-shot run. Args: [today] HH:MM
cmd_schedule() {
  [[ "${1:-}" == "today" ]] && shift
  local arg_time="${1:-}"
  [[ -n "${arg_time}" ]] || usage
  [[ "${arg_time}" =~ ^([0-9]{1,2}):([0-9]{2})$ ]] || die "invalid time '${arg_time}' — expected HH:MM (24h)"
  local h=$((10#${BASH_REMATCH[1]})) m=$((10#${BASH_REMATCH[2]}))
  ((h <= 23)) || die "hour out of range in '${arg_time}'"
  ((m <= 59)) || die "minute out of range in '${arg_time}'"

  # Set the plist fire time.
  "${plistbuddy}" -c "Set :StartCalendarInterval:Hour ${h}" "${plist_real}"
  "${plistbuddy}" -c "Set :StartCalendarInterval:Minute ${m}" "${plist_real}"

  # Record the date this run is armed for. The plist sits in ~/Library/LaunchAgents,
  # so launchd reloads it at every login; after a reboot or a slept-through 22:00 it
  # fires at the next HH:MM, possibly days later (10/9 armed, fired Sat 10/10).
  # run-nightly.sh skips any fire whose date doesn't match this marker.
  mkdir -p "${HOME}/.cache/dispatch"
  date '+%Y-%m-%d' >"${HOME}/.cache/dispatch/good-night-armed-for"

  # (Re)load the agent so it fires at the next HH:MM (today if not yet passed).
  local domain
  domain="gui/$(id -u)"
  launchctl bootout "${domain}/${label}" 2>/dev/null || true
  launchctl bootstrap "${domain}" "${plist_link}"

  # Warn if HH:MM already passed today (launchd would fire tomorrow, not tonight).
  local hh mm now_min target_min
  hh="$(date +%H)"
  mm="$(date +%M)"
  now_min=$((10#${hh} * 60 + 10#${mm}))
  target_min=$((h * 60 + m))
  if ((target_min <= now_min)); then
    warn "$(printf '%02d:%02d' "${h}" "${m}") already passed today — launchd will fire tomorrow, not tonight"
  fi

  # One-time power wake at (target - offset) today.
  local wake_min wh wm wake_dt
  wake_min=$(((target_min - wake_offset_min + 1440) % 1440))
  wh=$((wake_min / 60))
  wm=$((wake_min % 60))
  wake_dt="$(date '+%m/%d/%Y') $(printf '%02d:%02d:00' "${wh}" "${wm}")"
  if repeat_wake_covers "${wh}" "${wm}"; then
    log "repeating power wake at $(printf '%02d:%02d' "${wh}" "${wm}") covers today — no sudo needed"
  else
    log "scheduling one-time power wake at ${wake_dt} (approve with TouchID)"
    sudo pmset schedule wake "${wake_dt}" ||
      die "power-wake auth cancelled/failed — agent is loaded but no wake scheduled"
  fi
  warn "scheduled wake is honored only on AC power; keep the Mac plugged in"

  log "good-night armed (one-shot) for today $(printf '%02d:%02d' "${h}" "${m}")"
}

main() {
  check_preconditions
  case "${1:-}" in
  schedule)
    shift
    cmd_schedule "$@"
    ;;
  *) usage ;;
  esac
}

main "$@"
