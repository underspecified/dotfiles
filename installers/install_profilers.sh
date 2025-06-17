#!/bin/bash

install_profilers() {
    # Install profilers
    sudo apt-get install -y psensor stress

    (mkdir -p ~/git && \
     cd ~/git && \
     git clone https://github.com/wilicc/gpu-burn.git
     cd gpu-burn && \
     make)
}

install_profilers
