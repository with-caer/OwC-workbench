#!/bin/sh
#
# Performs the one-time installation and configuration
# of the default user account on Fedora or Rocky Linux.
#

export WORKBENCH_USER_NAME="${WORKBENCH_USER_NAME:-$(whoami)}"

# Require the Pulumi configuration file to exist before performing setup.
if [ ! -e pulumi/Pulumi.dev.yaml ]; then
  echo "please create a pulumi/Pulumi.dev.yaml file, containing:"
  cat << EOF
config:
  workbench:name: "workbench"

  cloudflare:apiToken: "CLOUDFLARE_API_TOKEN"

  cf:account_id: "CLOUDFLARE_ACCOUNT_ID"
  cf:team_name: "CLOUDFLARE_TEAM_NAME"
  cf:policy_id: "CLOUDFLARE_ZERO_ACCESS_POLICY_ID"
  cf:app_domain: "CLOUDFLARE_ROOT_DOMAIN"
  cf:app_subdomain: "CLOUDFLARE_SUB_DOMAIN"
EOF
  exit 1
fi

# TODO: This step may not be necessary on desktop installations,
#       since they often make the default user a sudoer on install.
# Make user sudoer.
# echo "${WORKBENCH_USER_EMAIL} ALL=(ALL:ALL) NOPASSWD: ALL" > /etc/sudoers.d/${WORKBENCH_USER_EMAIL}

# Disable the sudoer password requirement.
sudo touch /etc/sudoers.d/${WORKBENCH_USER_NAME}
echo "${WORKBENCH_USER_NAME} ALL=(ALL) NOPASSWD:ALL" | sudo tee /etc/sudoers.d/${WORKBENCH_USER_NAME}
sudo chmod 0440 /etc/sudoers.d/${WORKBENCH_USER_NAME}

# Install code-server systemd service,
# which will run as the workbench user.
sudo tee /etc/systemd/system/code-server.service <<EOF
[Unit]
Description=code-server
After=multi-user.target

[Service]
User=${WORKBENCH_USER_NAME}
ExecStart=/usr/bin/code-server --disable-telemetry --disable-getting-started-override --auth none --bind-addr localhost:31545
Type=simple
Restart=on-failure

[Install]
WantedBy=multi-user.target
EOF

# Activate code-server.
sudo systemctl enable --now code-server

# Configure Pulumi.
curl -fsSL https://get.pulumi.com | sh
export PATH="${PATH}:~/.pulumi/bin"
pulumi login --local

# Provision Cloudflare tunnel.
pulumi install -C pulumi
pulumi up -C pulumi
CLOUDFLARE_TUNNEL_TOKEN = $(pulumi stack -C pulumi output workbench_tunnel_token)

# Install cloudflared tunnel, exposing the system to the internet.
cloudflared service install $CLOUDFLARE_TUNNEL_TOKEN