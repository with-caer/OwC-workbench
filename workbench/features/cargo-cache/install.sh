#!/bin/sh
set -e

if [ ! -f /etc/redhat-release ]; then
    echo "this feature is designed for Fedora and Rocky Workbenches"
    exit 1
fi

# Install cargo-chef.
cargo binstall cargo-chef

# Add the configured source directory to the environment.
cat >> ~/.profile << EOF
WORKBENCH_CARGO_CACHE_SRC=${SRC}
WORKBENCH_CARGO_CACHE_FLAGS=${FLAGS}
EOF