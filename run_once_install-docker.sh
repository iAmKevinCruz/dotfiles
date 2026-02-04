#!/bin/bash
# Install Docker Engine on Ubuntu/Debian (not Docker Desktop)
# This script runs once per machine via chezmoi
# Requires sudo access

set -e

# Only run on Linux
if [[ "$(uname -s)" != "Linux" ]]; then
    echo "Skipping Docker Engine install (not Linux)"
    exit 0
fi

# Skip if docker daemon is already installed and running
if command -v dockerd &> /dev/null && systemctl is-active --quiet docker 2>/dev/null; then
    echo "Docker Engine already installed and running"
    docker --version
    exit 0
fi

# Check for apt (Ubuntu/Debian)
if ! command -v apt-get &> /dev/null; then
    echo "apt-get not found - this script only supports Ubuntu/Debian"
    echo "Install Docker manually for your distribution"
    exit 0
fi

echo "Installing Docker Engine..."

# Add Docker's official GPG key
sudo apt-get update
sudo apt-get install -y ca-certificates curl
sudo install -m 0755 -d /etc/apt/keyrings
sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
sudo chmod a+r /etc/apt/keyrings/docker.asc

# Add the repository to apt sources
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
  $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

# Install Docker Engine with compose plugin
sudo apt-get update
sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

# Add current user to docker group (avoids needing sudo for docker commands)
sudo usermod -aG docker $USER

# Start and enable Docker
sudo systemctl start docker
sudo systemctl enable docker

echo "Docker Engine installed successfully!"
docker --version
docker compose version

echo ""
echo "NOTE: Log out and back in for docker group membership to take effect."
echo "      Or run: newgrp docker"
