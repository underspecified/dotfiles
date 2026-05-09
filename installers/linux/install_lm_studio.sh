#!/usr/bin/env bash
# Usage: install_lm_studio.sh
# Downloads the LM Studio AppImage to ~/.local/lm-studio.app/ and exposes
# an `lm-studio` shim on PATH via ~/.local/bin/.
set -euo pipefail

LM_STUDIO_VERSION="0.3.16-8"
LM_STUDIO_DIR="${HOME}/.local/lm-studio.app"
LM_STUDIO_APPIMAGE="LM-Studio-${LM_STUDIO_VERSION}-x64.AppImage"

install_lm_studio() {
    mkdir -p "${LM_STUDIO_DIR}"
    (
        cd "${LM_STUDIO_DIR}"
        wget -O "${LM_STUDIO_APPIMAGE}" \
            "https://installers.lmstudio.ai/linux/x64/${LM_STUDIO_VERSION}/${LM_STUDIO_APPIMAGE}"
        chmod +x "${LM_STUDIO_APPIMAGE}"
        ln -sf "${LM_STUDIO_APPIMAGE}" "LM-Studio-latest-x64.AppImage"
    )

    cat > "${LM_STUDIO_DIR}/lm-studio" << 'EOF'
#!/usr/bin/env bash
exec "${HOME}/.local/lm-studio.app/LM-Studio-latest-x64.AppImage" --no-sandbox "$@"
EOF

    chmod +x "${LM_STUDIO_DIR}/lm-studio"
    ln -sf "${LM_STUDIO_DIR}/lm-studio" "${HOME}/.local/bin/lm-studio"
}

install_lm_studio
