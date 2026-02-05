#!/bin/bash
# Install systemctl-tui via cargo
# This script runs once per machine via chezmoi

set -e

# Skip if already installed
if command -v systemctl-tui &> /dev/null; then
    echo "systemctl-tui already installed"
    systemctl-tui --version 2>/dev/null || true
    exit 0
fi

# Check for cargo
if ! command -v cargo &> /dev/null; then
    echo "cargo not found - please install Rust first"
    echo "Visit https://rustup.rs/ to install Rust"
    exit 1
fi

echo "Installing systemctl-tui..."
cargo install systemctl-tui --locked

echo "systemctl-tui installed successfully!"
systemctl-tui --version 2>/dev/null || true
