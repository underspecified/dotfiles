#!/usr/bin/env bash
# Usage: setup_display.sh [profile_name]
# Selects a display profile (one of the *.env files in ~/.config/display/) and
# regenerates i3/dunst/Xresources/kitty configs via i3_update_config.
# With no argument, lists profiles and prompts interactively.
set -euo pipefail
shopt -s nullglob

display_dir="$HOME/.config/display"
state_file="$HOME/.local/state/display_profile"

if [[ ! -d "$display_dir" ]]; then
  echo "error: $display_dir not found (lnk not initialized?)" >&2
  exit 1
fi

# Collect available profile names (strip dir + .env extension)
profiles=()
for f in "$display_dir"/*.env; do
  name="${f##*/}"
  profiles+=("${name%.env}")
done

if [[ ${#profiles[@]} -eq 0 ]]; then
  echo "error: no *.env profiles found in $display_dir" >&2
  exit 1
fi

choice="${1:-}"

if [[ -z "$choice" ]]; then
  echo "Available display profiles:"
  for i in "${!profiles[@]}"; do
    printf "  %d) %s\n" "$((i+1))" "${profiles[$i]}"
  done
  read -r -p "Select profile [1-${#profiles[@]}]: " idx
  if ! [[ "$idx" =~ ^[0-9]+$ ]] || (( idx < 1 || idx > ${#profiles[@]} )); then
    echo "error: invalid selection" >&2
    exit 1
  fi
  choice="${profiles[$((idx-1))]}"
fi

# Validate that the chosen profile actually exists
if [[ ! -f "$display_dir/${choice}.env" ]]; then
  echo "error: profile '$choice' not found ($display_dir/${choice}.env missing)" >&2
  echo "available: ${profiles[*]}" >&2
  exit 1
fi

mkdir -p "$(dirname "$state_file")"
echo "$choice" > "$state_file"
echo "set display profile -> $choice ($state_file)"

if command -v i3_update_config &>/dev/null; then
  i3_update_config
  echo "regenerated configs via i3_update_config"
else
  echo "note: i3_update_config not on PATH; run manually after install" >&2
fi
