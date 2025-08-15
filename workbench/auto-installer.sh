#!/bin/sh

# Exit on first error.
set -e

# Basic system configuration.
sudo ./configure-packages.sh
sudo ./configure-user.sh $(whoami)

# Networking configuration.
sudo ./configure-network.sh
sudo ./configure-code-server.sh $(whoami)

# Expose to internet.
./provision-code-server-network.sh

# Install default packages.
sudo ./install-default-packages.sh
./install-default-rust-packages.sh
./install-default-code-server-extensions.sh

# Install default settings.
cp default-vscode-setings.json ${HOME}/.local/share/code-server/User/settings.json
cat ./default-bashrc.sh >> ${HOME}/.bashrc
