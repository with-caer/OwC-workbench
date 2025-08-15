#!/bin/sh

# Exit on first error.
set -e

# Require the Pulumi configuration file to exist before performing provisioning steps.
if [ ! -e pulumi/Pulumi.dev.yaml ]; then
  echo "please create a pulumi/Pulumi.dev.yaml file, containing:"
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

# Register custom repositories.
sudo dnf config-manager addrepo --from-repofile=https://pkg.cloudflare.com/cloudflared-ascii.repo

# Install packages, then clean-up the DNF cache.
sudo dnf install -y cloudflared curl
sudo dnf -y clean all && rm -rf /var/cache && df -h && rm -rf /tmp/user-packages.txt

# Configure Pulumi.
curl -fsSL https://get.pulumi.com | sh
export PATH="${PATH}:~/.pulumi/bin"
~/.pulumi/bin/pulumi login --local

# Provision Cloudflare tunnel.
export PULUMI_CONFIG_PASSPHRASE=""
~/.pulumi/bin/pulumi stack -C pulumi init dev
~/.pulumi/bin/pulumi install -C pulumi
~/.pulumi/bin/pulumi up -C pulumi
CLOUDFLARE_TUNNEL_TOKEN=$(~/.pulumi/bin/pulumi stack -C pulumi output workbench_tunnel_token)

# Install cloudflared tunnel, exposing the system to the internet.
sudo cloudflared service install $CLOUDFLARE_TUNNEL_TOKEN