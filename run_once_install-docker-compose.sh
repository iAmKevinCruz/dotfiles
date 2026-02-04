#!/bin/bash
# Install docker compose plugin (platform-aware)
# This script runs once per machine via chezmoi

set -e

# Only install if docker CLI exists
if ! command -v docker &> /dev/null; then
    echo "Docker CLI not found, skipping compose plugin installation"
    exit 0
fi

# Skip if already installed
if docker compose version &> /dev/null; then
    echo "Docker Compose plugin already installed: $(docker compose version)"
    exit 0
fi

echo "Installing Docker Compose plugin..."

mkdir -p ~/.docker/cli-plugins

ARCH=$(uname -m)
OS=$(uname -s | tr '[:upper:]' '[:lower:]')

# Normalize architecture names
if [ "$ARCH" = "x86_64" ]; then
    ARCH="x86_64"
elif [ "$ARCH" = "aarch64" ] || [ "$ARCH" = "arm64" ]; then
    ARCH="aarch64"
else
    echo "Unsupported architecture: $ARCH"
    exit 1
fi

COMPOSE_VERSION="v2.32.4"
URL="https://github.com/docker/compose/releases/download/${COMPOSE_VERSION}/docker-compose-${OS}-${ARCH}"

echo "Downloading from: $URL"
curl -SL "$URL" -o ~/.docker/cli-plugins/docker-compose
chmod +x ~/.docker/cli-plugins/docker-compose

echo "Docker Compose plugin installed: $(docker compose version)"
