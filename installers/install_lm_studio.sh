#!/usr/bin/bash

install_lm_studio () {
    curl https://installers.lmstudio.ai/linux/x64/0.3.16-8/LM-Studio-0.3.16-8-x64.AppImage \
        --create-dirs \
        --output-dir ~/.local/lm-studio.app \
        --output LM-Studio-0.3.16-8-x64.AppImage

        cd ~/.local/lm-studio.app
    chmod +x LM-Studio-0.3.16-8-x64.AppImage
    ln -sf LM-Studio-0.3.16-8-x64.AppImage LM-Studio-latest-x64.AppImage

    cat << 'EOF' > ~/.local/lm-studio.app/lm-studio
#!/bin/bash

$HOME/.local/lm-studio.app/LM-Studio-latest-x64.AppImage --no-sandbox "$@"
EOF

    chmod +x ~/.local/lm-studio.app/lm-studio
    ln -sf ~/.local/lm-studio.app/lm-studio ~/.local/bin/
}

install_lm_studio
