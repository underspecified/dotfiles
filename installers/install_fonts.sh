#!/bin/bash

sudo apt install fontconfig

mkdir -p ~/.local/share/fonts
cd ~/.local/share/fonts

for font in iA-Writer Meslo; do
    wget https://github.com/ryanoasis/nerd-fonts/releases/download/v3.4.0/$font.tar.xz
    tar xf $font.tar.xz
    rm $font.tar.xz
done

fc-cache -fv
