#!/bin/bash

### 0. Purge docker packages
sudo apt remove docker.io docker-ce docker-ce-cli containerd.io

### 1. Install Prerequisites
sudo apt update
sudo apt install -y uidmap dbus-user-session


### 2. Install Rootless Docker
# Download and run the rootless installation script
curl -fsSL https://get.docker.com/rootless | sh

### 3. Set Environment Variables
# Add these to your shell profile (~/.bashrc, ~/.zshrc, etc.):
#export PATH=/home/$USER/bin:$PATH
#export DOCKER_HOST=unix:///run/user/$(id -u)/docker.sock

# Then reload your shell:
#rehash

### 4. Enable Rootless Docker Service
# Enable the user service
systemctl --user enable docker
systemctl --user start docker

# Enable lingering (allows services to start at boot without login)
sudo loginctl enable-linger $(whoami)

# 5. Verify Installation
docker version
docker run hello-world

### 6. Install Docker Compose for Rootless
# download the binary
mkdir -p ~/.docker/cli-plugins/
curl -SL "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o ~/.docker/cli-plugins/docker-compose
chmod +x ~/.docker/cli-plugins/docker-compose
