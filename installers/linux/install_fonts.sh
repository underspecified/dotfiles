#!/bin/bash

sudo apt install fontconfig

mkdir -p ~/.local/share/fonts
cd ~/.local/share/fonts

for font in iA-Writer Meslo; do
    wget https://github.com/ryanoasis/nerd-fonts/releases/download/v3.4.0/$font.tar.xz
    tar xf $font.tar.xz
    rm $font.tar.xz
done

# Upstream Nerd-Fonts ships iMWriting Quattro Bold with usWeightClass=400, so
# fontdb-based apps (e.g. Zed) render Regular requests with the bold file.
# Idempotent; skipped if uv is unavailable.
if command -v uv >/dev/null 2>&1; then
    uv run ~/.config/lnk/installers/linux/fix_imwriting_quat_weights.py
else
    echo "warning: uv not found; skipping iMWriting Quat weight patch" >&2
fi

fc-cache -fv
