#!/bin/sh

# Exit on first error.
set -e

# Check user.
if [[ $(/usr/bin/id -u) -ne 0 ]]; then
    echo "please run this script as root, or with sudo"
    exit 1
fi

# Check arguments.
if [ "$#" -lt 1 ]; then
    echo "please provide the default workbench user name. examples:\n"
    echo "  ./install-local.sh root"
    echo "  ./install-local.sh caer"
    echo "  ./install-local.sh sir-pancake-waffleton-the-thirty-tooth"
    exit 1
fi

# Parse arguments.
SCRIPT_DIR=$( cd -- "$( dirname -- "$0}" )" &> /dev/null && pwd )
WORKBENCH_USER_NAME=$1

# Check configuration.
if [ ! -e ${SCRIPT_DIR}/pulumi/Pulumi.dev.yaml ]; then
    echo "please create ${SCRIPT_DIR}/pulumi/Pulumi.dev.yaml, containing:"
    cat << EOF
config:
  cloudflare:apiToken: "CLOUDFLARE_API_TOKEN"

  account_id: "CLOUDFLARE_ACCOUNT_ID"
  team_name: "CLOUDFLARE_TEAM_NAME"
  policy_id: "CLOUDFLARE_ZERO_ACCESS_POLICY_ID"
  app_domain: "CLOUDFLARE_ROOT_DOMAIN"
  app_subdomain: "CLOUDFLARE_SUB_DOMAIN"
EOF
    exit 1
fi

# Install default settings.
cp ${SCRIPT_DIR}/assets/default-vscode-setings.json /home/${WORKBENCH_USER_NAME}/.local/share/code-server/User/settings.json
cat ${SCRIPT_DIR}/assets/default-bashrc.sh >> /home/${WORKBENCH_USER_NAME}/.bashrc

# InstallPyinfra dependencies.
dnf install pipx
pipx install pyinfra

# Execute PyInfra provisioner.
cd ${SCRIPT_DIR}/pyinfra
pyinfra inventory_local.py deploy.py -y
cd ${SCRIPT_DIR}

# Install Pulumi dependencies.
curl -fsSL https://get.pulumi.com | sh
export PATH="${PATH}:~/.pulumi/bin"
~/.pulumi/bin/pulumi login --local
export PULUMI_CONFIG_PASSPHRASE=""

# Execute Pulumi provisioner.
~/.pulumi/bin/pulumi stack -C pulumi init dev
~/.pulumi/bin/pulumi install -C pulumi
~/.pulumi/bin/pulumi up -C pulumi
CLOUDFLARE_TUNNEL_TOKEN=$(~/.pulumi/bin/pulumi stack -C pulumi output workbench_tunnel_token)

# Activate cloudflared tunnel.
cloudflared service install $CLOUDFLARE_TUNNEL_TOKEN
