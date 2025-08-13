#!/bin/sh

# Create user account.
useradd --groups wheel ${user_name}

# Make user sudoer and disable password requirement.
echo "${user_name} ALL=(ALL:ALL) NOPASSWD: ALL" > /etc/sudoers.d/${user_name}
chmod 0440 /etc/sudoers.d/${user_name}

# Grant user ownership over their home, just in case.
chown -R ${user_name}: /home/${user_name}

# Grant user group memberships.
usermod -a -G docker ${user_name}

# Install git-lfs to the user's account.
sudo -i -u caer git lfs install

# Install code-server systemd service,
# which will run as the new user account.
cat <<EOF-Setup > /etc/systemd/system/code-server.service
[Unit]
Description=code-server
After=multi-user.target

[Service]
User=${user_name}
ExecStart=/usr/bin/code-server --disable-telemetry --disable-getting-started-override --auth none --bind-addr localhost:31545
Type=simple
Restart=on-failure

[Install]
WantedBy=multi-user.target
EOF-Setup

# Enable systemd services.
systemctl enable code-server

# Install and run user's first-time setup script.
mkdir -p /home/${user_name}/.workbench
cat <<'EOF-Setup' > /home/${user_name}/.workbench/setup.sh
${user_setup_script}
EOF-Setup
chmod +x /home/${user_name}/.workbench/setup.sh

# Execute first-time setup.
sudo -i -u caer WORKBENCH_EMAIL=${user_email} sh -x -e /home/${user_name}/.workbench/setup.sh 2>&1 | tee -a /home/${user_name}/.workbench/setup.log || true
chown -R ${user_name}: /home/${user_name}/.workbench

# Install cloudflared tunnel, exposing the VM to the internet.
cloudflared service install ${cloudflare_tunnel_token}

reboot "Workspace setup complete; rebooting."