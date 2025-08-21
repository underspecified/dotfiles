#!/usr/bin/bash

CUR_DIR=$(realpath $(dirname "$0"))

CODENAME=$(lsb_release -cs)
RELEASE=$(lsb_release -rs | tr -d .)
[[ -n $NVIDIA_VERSION ]] && NVIDIA_PACKAGE="nvidia-open-$NVIDIA_VERSION" || NVIDIA_PACKAGE="nvidia-open"
[[ -n $CUDA_VERSION ]] && CUDA_PACKAGE="cuda-$NVIDIA_VERSION" || CUDA_PACKAGE="cuda"

install_nvidia_repo () {
    wget https://developer.download.nvidia.com/compute/cuda/repos/ubuntu${RELEASE}/x86_64/cuda-keyring_1.1-1_all.deb
    sudo dpkg -i cuda-keyring_1.1-1_all.deb
    rm cuda-keyring_1.1-1_all.deb
    sudo apt update

    wget https://developer.download.nvidia.com/compute/cuda/repos/ubuntu${RELEASE}/x86_64/cuda-archive-keyring.gpg
    sudo mv cuda-archive-keyring.gpg /usr/share/keyrings/cuda-archive-keyring.gpg

echo "deb [signed-by=/usr/share/keyrings/cuda-archive-keyring.gpg] https://developer.download.nvidia.com/compute/cuda/repos/repos/ubuntu${RELEASE}/ /" \
        | tee /etc/apt/sources.list.d/cuda-repos-ubuntu${RELEASE}.list
}

### install nvidia drivers and cuda
install_nvidia_drivers () {
    sudo apt update && \
    sudo apt install -y $NVIDIA_PACKAGE
}

install_cuda () {
    sudo apt update && \
    sudo apt install -y $CUDA_PACKAGE nvidia-cuda-toolkit nvidia-cuda-dev
}

bash "$CUR_DIR/remove_nvidia_drivers.sh"
install_nvidia_repo
install_nvidia_drivers
install_cuda
