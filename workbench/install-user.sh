#!/bin/sh
#
# Performs the one-time installation and configuration
# of the default user account on Fedora or Rocky Linux.
#

export WORKBENCH_USER_NAME="${WORKBENCH_USER_NAME:-$(whoami)}"

# TODO: This step may not be necessary on desktop installations,
#       since they often make the default user a sudoer on install.
# Make user sudoer.
# echo "${WORKBENCH_USER_EMAIL} ALL=(ALL:ALL) NOPASSWD: ALL" > /etc/sudoers.d/${WORKBENCH_USER_EMAIL}

# Disable the sudoer password requirement.
sudo chmod 0440 /etc/sudoers.d/${WORKBENCH_USER_NAME}

# Install code-server systemd service,
# which will run as the workbench user.
sudo cat <<EOF > /etc/systemd/system/code-server.service
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

# Install cloudflared tunnel, exposing the system to the internet.
# cloudflared service install ${cloudflare_tunnel_token}