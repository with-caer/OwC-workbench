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
script_dir=$( cd -- "$( dirname -- "$0}" )" &> /dev/null && pwd )
workbench_user_name=$1

# Check configuration.
if [ ! -e ${script_dir}/pulumi/Pulumi.dev.yaml ]; then
    echo "please create ${script_dir}/pulumi/Pulumi.dev.yaml, containing:"
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
cp ${script_dir}/assets/default-vscode-setings.json /home/${workbench_user_name}/.local/share/code-server/User/settings.json
cat ${script_dir}/assets/default-bashrc.sh >> /home/${workbench_user_name}/.bashrc

# Install Pyinfra dependencies.
dnf install pipx
pipx install pyinfra

# Execute PyInfra provisioner.
cd ${script_dir}/pyinfra
pyinfra inventory_local.py deploy.py -y
cd ${script_dir}

# Install tools.
./${script_dir}/install-tools.sh

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
