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
# The power-wake is set via a GUI admin-auth prompt (osascript), not sudo, so it
# works from non-TTY contexts (Claude Bash tool, /good-morning) where sudo can't
# read a password. Wake is honored only on AC power.
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
  (( h <= 23 )) || die "hour out of range in '${arg_time}'"
  (( m <= 59 )) || die "minute out of range in '${arg_time}'"

  # Set the plist fire time.
  "${plistbuddy}" -c "Set :StartCalendarInterval:Hour ${h}" "${plist_real}"
  "${plistbuddy}" -c "Set :StartCalendarInterval:Minute ${m}" "${plist_real}"

  # (Re)load the agent so it fires at the next HH:MM (today if not yet passed).
  local domain
  domain="gui/$(id -u)"
  launchctl bootout "${domain}/${label}" 2>/dev/null || true
  launchctl bootstrap "${domain}" "${plist_link}"

  # Warn if HH:MM already passed today (launchd would fire tomorrow, not tonight).
  local hh mm now_min target_min
  hh="$(date +%H)"; mm="$(date +%M)"
  now_min=$(( 10#${hh} * 60 + 10#${mm} ))
  target_min=$(( h * 60 + m ))
  if (( target_min <= now_min )); then
    warn "$(printf '%02d:%02d' "${h}" "${m}") already passed today — launchd will fire tomorrow, not tonight"
  fi

  # One-time power wake at (target - offset) today.
  local wake_min wh wm wake_dt
  wake_min=$(( (target_min - wake_offset_min + 1440) % 1440 ))
  wh=$(( wake_min / 60 )); wm=$(( wake_min % 60 ))
  wake_dt="$(date '+%m/%d/%Y') $(printf '%02d:%02d:00' "${wh}" "${wm}")"
  # GUI admin-auth prompt (works without a TTY, unlike sudo). Pops the native
  # macOS auth window; pmset runs as root once authorized.
  log "scheduling one-time power wake at ${wake_dt} (approve the auth prompt)"
  osascript -e "do shell script \"/usr/bin/pmset schedule wake \\\"${wake_dt}\\\"\" with administrator privileges" \
    || die "power-wake auth cancelled/failed — agent is loaded but no wake scheduled"
  warn "scheduled wake is honored only on AC power; keep the Mac plugged in"

  log "good-night armed (one-shot) for today $(printf '%02d:%02d' "${h}" "${m}")"
}

main() {
  check_preconditions
  case "${1:-}" in
    schedule) shift; cmd_schedule "$@" ;;
    *) usage ;;
  esac
}

main "$@"
