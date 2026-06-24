#!/usr/bin/env bash
# Usage: bash setup_good_night_automation.sh
#
# Sets up the automated nightly /good-night on macOS:
#   1. Loads the launchd agent (com.eric.good-night-nightly) that fires the
#      gate-free good-night at 21:30 via dispatch wake-then-run. The plist is
#      deployed by lnk (.lnk.macos -> ~/Library/LaunchAgents/); this just loads it.
#   2. Schedules a daily power wake one minute earlier (pmset) so the Mac is
#      awake when launchd fires — otherwise a sleeping Mac defers the run until
#      its next wake (which would land in the morning, after good-morning).
#
# Idempotent. The pmset step needs sudo (will prompt). Scheduled wake is only
# honored on AC power — keep the Mac plugged in overnight for reliable runs.
set -euo pipefail

# shellcheck source=SCRIPTDIR/../lib.sh
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/../lib.sh"

label="com.eric.good-night-nightly"
plist="${HOME}/Library/LaunchAgents/${label}.plist"
# WAKE_TIME must stay one minute before the plist's StartCalendarInterval (21:30).
wake_time="21:29:00"
wake_days="MTWRFSU"  # every day; good-night runs nightly (it self-skips weekends only for scheduling good-morning)

check_preconditions() {
  [[ "$(uname -s)" == "Darwin" ]] || die "good-night automation is macOS-only"
  [[ -e "${plist}" ]] || die "plist not found at ${plist} — run 'lnk pull' first to restore the symlink"
}

# Load (or reload) the launchd agent in the current user's GUI domain.
load_launchd_agent() {
  local domain
  domain="gui/$(id -u)"
  if launchctl print "${domain}/${label}" >/dev/null 2>&1; then
    log "launchd agent already loaded — reloading"
    launchctl bootout "${domain}/${label}" 2>/dev/null || true
  fi
  launchctl bootstrap "${domain}" "${plist}"
  log "loaded ${label} (fires 21:30 daily)"
}

# Schedule a daily power wake just before the launchd fire time.
schedule_wake() {
  log "scheduling daily power wake at ${wake_time} (needs sudo)"
  sudo pmset repeat wakeorpoweron "${wake_days}" "${wake_time}"
  log "wake scheduled — verify with: pmset -g sched"
  warn "scheduled wake is honored only on AC power; keep the Mac plugged in overnight"
}

main() {
  check_preconditions
  load_launchd_agent
  schedule_wake
  log "good-night automation set up"
}

main "$@"
