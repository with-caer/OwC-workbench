#!/bin/sh
#
# Performs the one-time installation and configuration
# of a workbench on Fedora or Rocky Linux within a
# privileged ("root") context.
#

# Exit on first error.
set -e

# Configure DNF to find the fastest mirror
# and download packages in parallel; without
# these options, some hosts will timeout their
# package installations.
echo fastestmirror=True >> /etc/dnf/dnf.conf
echo max_parallel_downloads=10 >> /etc/dnf/dnf.conf

# Register custom repositories.
dnf config-manager --add-repo https://pkg.cloudflare.com/cloudflared-ascii.repo
dnf install -y epel-release

# Refresh repositories and packages.
dnf upgrade -y --refresh

# Install packages, then clean-up the DNF cache.
dnf install -y sudo fail2ban openssh-server cloudflared wget git
dnf -y clean all && rm -rf /var/cache && df -h && rm -rf /tmp/user-packages.txt

# Active SSH server.
systemctl enable --now sshd

# Disallow password and root login via SSH.
sed -i -E 's/#?\\s*PasswordAuthentication\\s*.+$/PasswordAuthentication no/' /etc/ssh/sshd_config,
sed -i -E 's/#?\\s*PermitRootLogin\\s*.+$/PermitRootLogin no/' /etc/ssh/sshd_config,
sed -i -E 's/#?\\s*PermitEmptyPasswords\\s*.+$/PermitEmptyPasswords no/' /etc/ssh/sshd_config,
cat <<EOF > /etc/ssh/sshd_config.d/workbench.conf
PasswordAuthentication no
PermitRootLogin no
PermitEmptyPasswords no
EOF

# Activate firewall.
systemctl enable --now firewalld

# Disallow most ingress traffic in the public zone;
# cloudflared will control public ingress.
firewall-cmd --permanent --zone=public --remove-service=ssh
firewall-cmd --permanent --zone=public --remove-service=http
firewall-cmd --permanent --zone=public --remove-service=https

# Allow SSH ingress traffic on the internal zone from private IPs.
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

# Install code server.
CODE_SERVER_RPM=code-server-${var.code_server_version}-${var.code_server_arch}.rpm
wget https://github.com/coder/code-server/releases/download/v${var.code_server_version}/${CODE_SERVER_RPM}
rpm -K ${CODE_SERVER_RPM}
dnf install -y ./${CODE_SERVER_RPM}
rm ${CODE_SERVER_RPM}

# Configure code server.
sh assets/patch-code-server.sh