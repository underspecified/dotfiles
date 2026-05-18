#!/usr/bin/env bash
# Usage: setup_display.sh [profile_name]
# Selects a display profile by symlinking ~/.config/display/env to one of the
# *.env files in that directory, then regenerates i3/dunst/Xresources/kitty
# configs via i3_update_config. With no argument, lists profiles and prompts.
set -euo pipefail
shopt -s nullglob

display_dir="$HOME/.config/display"
env_link="$display_dir/env"

if [[ ! -d "$display_dir" ]]; then
  echo "error: $display_dir not found (lnk not initialized?)" >&2
  exit 1
fi

# Collect available profile names (strip dir + .env extension; skip the env link itself)
profiles=()
for f in "$display_dir"/*.env; do
  name="${f##*/}"
  [[ "$name" == "env" ]] && continue
  profiles+=("${name%.env}")
done

if [[ ${#profiles[@]} -eq 0 ]]; then
  echo "error: no *.env profiles found in $display_dir" >&2
  exit 1
fi

choice="${1:-}"

# Re-run guard: if invoked from the unattended bootstrap path (no arg) and
# a profile is already selected, log + exit instead of prompting -- otherwise
# `bash bootstrap.sh` would hang on stdin during updates.
if [[ -z "$choice" && -L "$env_link" ]]; then
  current="$(readlink "$env_link")"
  echo "display profile already set: ${current%.env} ($env_link -> $current)"
  exit 0
fi

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

target="${choice}.env"
if [[ ! -f "$display_dir/$target" ]]; then
  echo "error: profile '$choice' not found ($display_dir/$target missing)" >&2
  echo "available: ${profiles[*]}" >&2
  exit 1
fi

# Symlink target is relative so the link works regardless of how display/ is mounted
ln -sfn "$target" "$env_link"
echo "set display profile -> $choice ($env_link -> $target)"

if command -v i3_update_config &>/dev/null; then
  i3_update_config
  echo "regenerated configs via i3_update_config"
else
  echo "note: i3_update_config not on PATH; run manually after install" >&2
fi
