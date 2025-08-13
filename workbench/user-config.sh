#!/bin/sh
#
# Performs the one-time configuration of the default
# user account on Fedora or Rocky Linux.
#

# Install development packages.
sudo dnf install -y rustup gcc g++ cmake openssl openssl-devel awk curl wget hostname git

# Configure Git.
git config --global user.name "${WORKBENCH_USER_NAME}"
git config --global user.email "${WORKBENCH_USER_EMAIL}"

# Install Cargo for Rust.
rustup-init -y
echo PATH="${HOME}/.cargo/bin:${PATH}" >> ${HOME}/.profile
. "$HOME/.cargo/env"
rustup component add rustfmt
rustup component add clippy

# Install Rust utilities.
curl -L --proto '=https' --tlsv1.2 -sSf https://raw.githubusercontent.com/cargo-bins/cargo-binstall/main/install-from-binstall-release.sh | bash
cargo binstall --no-confirm cargo-audit cargo-server

# Install VSCode extensions.
code-server --install-extension rust-lang.rust-analyzer
code-server --install-extension tamasfe.even-better-toml
code-server --install-extension beardedbear.beardedtheme

# Configure VSCode.
cat <<EOF > ${HOME}/.local/share/code-server/User/settings.json
{
    "files.watcherExclude": {
        "**/target/**": true
    },

    "window.autoDetectColorScheme": true,
    "window.autoDetectHighContrast": false,

    "workbench.preferredDarkColorTheme": "Bearded Theme Monokai Terra",
    "workbench.preferredLightColorTheme": "Bearded Theme feat. Melle Julie Light",
    "workbench.colorTheme": "Bearded Theme feat. Melle Julie Light",
    "workbench.startupEditor": "none",
    "workbench.editor.enablePreview": false,
    "workbench.activityBar.location": "top",
    
    "editor.wordWrap": "on",
    "editor.fontFamily": "'Inconsolata', Menlo, Monaco, 'Courier New', monospace",
    "editor.fontSize": 15,
    "editor.fontLigatures": true,
    "editor.cursorStyle": "underline",
    "editor.minimap.enabled": false,
    
    "terminal.integrated.cursorBlinking": true,
    "terminal.integrated.cursorStyle": "underline",
    "terminal.integrated.localEchoEnabled": "on",
    "terminal.integrated.localEchoStyle": "bold",
    "terminal.integrated.localEchoLatencyThreshold": 10
}
EOF