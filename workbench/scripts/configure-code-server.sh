#!/bin/sh

CODE_SERVER_VERSION="${CODE_SERVER_VERSION:-4.103.0}"
CODE_SERVER_ARCH="${CODE_SERVER_ARCH:-amd64}"
USER_NAME=$1

# Exit on first error.
set -e

# Install packages, then clean-up the DNF cache.
dnf install -y wget
dnf -y clean all && rm -rf /var/cache && df -h && rm -rf /tmp/user-packages.txt

# Install code server.
CODE_SERVER_RPM=code-server-${CODE_SERVER_VERSION}-${CODE_SERVER_ARCH}.rpm
wget https://github.com/coder/code-server/releases/download/v${CODE_SERVER_VERSION}/${CODE_SERVER_RPM}
rpm -K ${CODE_SERVER_RPM}
dnf install -y ./${CODE_SERVER_RPM}
rm ${CODE_SERVER_RPM}

# Install code-server systemd service.
tee /etc/systemd/system/code-server.service <<EOF
[Unit]
Description=code-server
After=multi-user.target

[Service]
User=${USER_NAME}
ExecStart=/usr/bin/code-server --disable-telemetry --disable-getting-started-override --auth none --bind-addr localhost:31545
Type=simple
Restart=on-failure

[Install]
WantedBy=multi-user.target
EOF

# Activate code-server.
systemctl enable --now code-server

# Configure code server.
cd ../assets
sh patch-code-server.sh
cd ../scripts