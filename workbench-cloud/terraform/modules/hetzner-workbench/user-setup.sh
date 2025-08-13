#!/bin/sh

# Install packages.
sudo dnf config-manager --add-repo https://rpm.releases.hashicorp.com/RHEL/hashicorp.repo
sudo dnf install -y gcc g++ openssl openssl-devel packer terraform chromium

# Alias packer to pkr since it's name
# conflicts with another package.
echo alias pkr="/usr/bin/packer" >> ${HOME}/.profile

# Install Rustup and Cargo.
curl https://sh.rustup.rs -sSf | sh -s -- -y
echo PATH="${HOME}/.cargo/bin:${PATH}" >> ${HOME}/.profile
. "$HOME/.cargo/env"

# Configure Cargo.
cat <<EOF > ${HOME}/.cargo/config.toml
[build]
# Restrict builds to using all but
# one core, since some VMs will freeze
# if all cores get used for building.
jobs = $(($(nproc --all) - 1))

EOF

# Install Rust toolchain.
rustup toolchain install 1.78.0

# Enable Rust extensions.
rustup component add rustfmt
rustup component add clippy

# Install Rust utilities.
curl -L --proto '=https' --tlsv1.2 -sSf https://raw.githubusercontent.com/cargo-bins/cargo-binstall/main/install-from-binstall-release.sh | bash
cargo binstall --no-confirm cargo-audit

# Install VSCode extensions.
code-server --install-extension gitlab.gitlab-workflow
code-server --install-extension hashicorp.hcl
code-server --install-extension hashicorp.terraform
code-server --install-extension rust-lang.rust-analyzer
code-server --install-extension tamasfe.even-better-toml
code-server --install-extension spacebox.monospace-idx-theme

# Configure VSCode.
cat <<EOF > ${HOME}/.local/share/code-server/User/settings.json
{
    "window.autoDetectColorScheme": true,
    "window.autoDetectHighContrast": false,

    "workbench.preferredDarkColorTheme": "Monospace IDX Dark",
    "workbench.preferredLightColorTheme": "Monospace IDX Light",
    "workbench.colorTheme": "Monospace IDX Light",
    "workbench.startupEditor": "none",
    "workbench.editor.enablePreview": false,
    "workbench.activityBar.location": "top",
    
    "editor.wordWrap": "on",
    "editor.fontFamily": "'Fira Code', Menlo, Monaco, 'Courier New', monospace",
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

# Configure Git.
git config --global user.email "${WORKBENCH_EMAIL}"
git config --global user.name "$(whoami)"

# Configure interactive shell.
echo ". ${HOME}/.profile" >> ${HOME}/.bashrc
cat <<'EOF' >> ${HOME}/.bashrc
# Alias code to code-server, for convenience.
alias code="code-server"

# Install Git shell completion.
source /usr/share/git-core/contrib/completion/git-prompt.sh

# Cache terminal color codes for the prompt.
# \x01 and \x02 (or \[ and \]) are open/close tags for
# "non-printing" characters; we want BASH
# to know that these color codes don't get
# rendered on-screen, or else things like the
# history command will mangle the prompt.
GREEN=\\x01$(tput setaf 2)\\x02
MAGENTA=\\x01$(tput setaf 198)\\x02
MAGENTA_B=\\[$(tput setaf 198)\\]
PURPLE=\\x01$(tput setaf 5)\\x02
FAINT=\\x01$(tput setaf 255)\\x02
BOLD=\\x01$(tput bold)\\x02
NORMAL=\\x01$(tput sgr0)\\x02
NORMAL_B=\\[$(tput sgr0)\\]

# Generates a pretty bash prompt.
generate_prompt() {

	# Get username and hostname.
	PROMPT_USER=$(whoami)
	PROMPT_HOST=$(hostname -s)

	# Get current working directory,
	# abbreviating HOME to ~ and replacing
	# path names with the first character of
	# their path (ignoring . in dotfiles).
	PROMPT_PATH=$(sed "s:\([^/\.]\)[^/]*/:\1/:g" <<< ${PWD/#$HOME/\~})

	# Get Git info, if any.
	PROMPT_GIT=$(__git_ps1 "${NORMAL}${FAINT}(git: ${MAGENTA}%s${FAINT})")

	# Print prompt.
	echo -e "${GREEN}${PROMPT_USER}${NORMAL}${FAINT}@${GREEN}${PROMPT_HOST} ${BOLD}${PURPLE}${PROMPT_PATH} ${PROMPT_GIT}\n${BOLD}${PURPLE}>${NORMAL}${PURPLE} "
}

# Install bash prompt customizations.
PS1='$(generate_prompt)'
PS2="${NORMAL_B}${MAGENTA_B}> "
PS0="${NORMAL_B}"

# Insert a newline after every command executed,
# except the clear command (since we don't want
# newlines at the top of an empty terminal).
PROMPT_COMMAND="export PROMPT_COMMAND=echo"
alias clear="unset PROMPT_COMMAND; clear; PROMPT_COMMAND='export PROMPT_COMMAND=echo'"
EOF