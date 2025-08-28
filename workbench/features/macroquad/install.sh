#!/bin/sh
set -e

if [ ! -f /etc/redhat-release ]; then
    echo "this feature is designed for Fedora and Rocky Workbenches"
    exit 1
fi

# Install OS-level Macroquad dependencies.
dnf install -y libX11-devel libXi-devel mesa-libGL-devel alsa-lib-devel

# Install the Rust WASM cross-compilation target.
rustup target add wasm32-unknown-unknown