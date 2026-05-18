#!/usr/bin/env bash
# Re-run = per-family check. Each family is downloaded + extracted only
# when no representative ttf is already in the fonts dir.
set -euo pipefail

# shellcheck source=SCRIPTDIR/../lib.sh
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/../lib.sh"

FONTS_DIR="${HOME}/.local/share/fonts"

# Per-family sentinel: pick a filename pattern unique to each Nerd Fonts
# release. If the pattern matches an existing file, skip the download.
declare -A FONT_SENTINELS=(
  [iA-Writer]="iMWritingMono*.ttf"
  [Meslo]="MesloLG*.ttf"
)

sudo apt install -y fontconfig

mkdir -p "${FONTS_DIR}"
cd "${FONTS_DIR}"

any_changed=0
for font in "${!FONT_SENTINELS[@]}"; do
    # shellcheck disable=SC2206  # word splitting on glob is intended
    matches=( ${FONT_SENTINELS[$font]} )
    if [[ -f "${matches[0]}" ]]; then
        log "${font}: present; skipping download"
        continue
    fi
    log "${font}: downloading + extracting"
    wget "https://github.com/ryanoasis/nerd-fonts/releases/download/v3.4.0/${font}.tar.xz"
    tar xf "${font}.tar.xz"
    rm "${font}.tar.xz"
    any_changed=1
done

# Upstream Nerd-Fonts ships iMWriting Quattro Bold with usWeightClass=400, so
# fontdb-based apps (e.g. Zed) render Regular requests with the bold file.
# Idempotent; skipped if uv is unavailable.
if command -v uv >/dev/null 2>&1; then
    uv run "${HOME}/.config/lnk/installers/linux/fix_imwriting_quat_weights.py"
else
    warn "uv not found; skipping iMWriting Quat weight patch"
fi

# fc-cache is cheap, but only worth the I/O if anything actually changed.
if [[ "${any_changed}" -eq 1 ]]; then
    fc-cache -fv
else
    log "no font changes; skipping fc-cache rebuild"
fi
