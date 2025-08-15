#!/bin/sh

sudo ./install-default-packages.sh
./install-default-rust-packages.sh
./install-default-code-server-extensions.sh

cp default-vscode-setings.json ${HOME}/.local/share/code-server/User/settings.json
cat ./default-bashrc.sh >> ${HOME}/.bashrc
