#!/bin/sh

# Exit on first error.
set -e

cd pyinfra
pyinfra inventory_local.py deploy.py -y
cd ..

# Expose to internet.
sh provision-code-server-network.sh

# Install default settings.
cp assets/default-vscode-setings.json ${HOME}/.local/share/code-server/User/settings.json
cat assets/default-bashrc.sh >> ${HOME}/.bashrc
