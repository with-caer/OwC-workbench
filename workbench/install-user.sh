#!/bin/sh
#
# Performs the one-time installation and configuration
# of the default user account on Fedora or Rocky Linux.
#

# Check arguments.
if [ "$#" -lt 2 ]; then
    echo "please provide an email address for the current user"
    exit 1
fi

WORKBENCH_USER_EMAIL=$1
WORKBENCH_USER_NAME="${WORKBENCH_USER_NAME:-$(whoami)}"

# TODO: This step may not be necessary on desktop installations,
#       since they often make the default user a sudoer on install.
# Make user sudoer.
# echo "${WORKBENCH_USER_EMAIL} ALL=(ALL:ALL) NOPASSWD: ALL" > /etc/sudoers.d/${WORKBENCH_USER_EMAIL}

# Disable the sudoer password requirement.
chmod 0440 /etc/sudoers.d/${WORKBENCH_USER_NAME}

# Install code-server systemd service,
# which will run as the workbench user.
cat <<EOF > /etc/systemd/system/code-server.service
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
systemctl enable --now code-server