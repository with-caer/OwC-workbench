#!/bin/sh

# Exit on first error.
set -e

cd scripts

# Basic system configuration.
sudo sh configure-packages.sh
sudo sh configure-user.sh $(whoami)

# Networking configuration.
sudo sh configure-network.sh
sudo sh configure-code-server.sh $(whoami)

# Expose to internet.
sh provision-code-server-network.sh

# Install default packages.
sudo sh install-default-packages.sh
sh install-default-rust-packages.sh
sh install-default-code-server-extensions.sh

# Install default settings.
cp ../assets/default-vscode-setings.json ${HOME}/.local/share/code-server/User/settings.json
cat ../assets/default-bashrc.sh >> ${HOME}/.bashrc
