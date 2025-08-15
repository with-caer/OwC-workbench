#!/bin/sh

# Exit on first error.
set -e

# Install packages, then clean-up the DNF cache.
dnf install -y sudo fail2ban openssh-server
dnf -y clean all && rm -rf /var/cache && df -h && rm -rf /tmp/user-packages.txt

# Activate SSH server.
systemctl enable --now sshd

# Disallow password and root login via SSH.
sed -i -E 's/#?\\s*PasswordAuthentication\\s*.+$/PasswordAuthentication no/' /etc/ssh/sshd_config
sed -i -E 's/#?\\s*PermitRootLogin\\s*.+$/PermitRootLogin no/' /etc/ssh/sshd_config
sed -i -E 's/#?\\s*PermitEmptyPasswords\\s*.+$/PermitEmptyPasswords no/' /etc/ssh/sshd_config
cat <<EOF > /etc/ssh/sshd_config.d/workbench.conf
PasswordAuthentication no
PermitRootLogin no
PermitEmptyPasswords no
EOF

# Activate firewall.
systemctl enable --now firewalld
firewall-cmd --permanent --zone=public --remove-service=ssh
firewall-cmd --permanent --zone=trusted --add-service=ssh

# Activate fail2ban.
systemctl enable --now fail2ban

# Configure fail2ban.
cat <<EOF > /etc/fail2ban/jail.local
[DEFAULT]
bantime = 3600
[sshd]
enabled = true
EOF