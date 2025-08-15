#!/bin/sh

# Install Cargo for Rust.
rustup-init -y
echo PATH="${HOME}/.cargo/bin:${PATH}" >> ${HOME}/.profile
. "$HOME/.cargo/env"
rustup component add rustfmt
rustup component add clippy

# Install Rust utilities.
curl -L --proto '=https' --tlsv1.2 -sSf https://raw.githubusercontent.com/cargo-bins/cargo-binstall/main/install-from-binstall-release.sh | bash
cargo binstall --no-confirm cargo-audit cargo-server