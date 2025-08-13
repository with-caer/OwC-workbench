packer {
  required_plugins {
    hcloud = {
      source  = "github.com/hetznercloud/hcloud"
      version = " >= 1.4.0"
    }
  }
}

source "hcloud" "image" {
  token               = "${var.hetzner_api_token}"
  image               = "rocky-9"
  location            = "${var.hetzner_server_location}"
  ssh_username        = "root"
  server_type         = "${var.hetzner_server_class}"
  upgrade_server_type = "${var.hetzner_server_class_build}"
  snapshot_name       = "${var.workbench_image_name}-${timestamp()}"
  snapshot_labels = {
    "workbench/image"  = "${var.workbench_image_name}"
    "workbench/distro" = "rocky-9"
  }
}

build {
  sources = [
    "source.hcloud.image"
  ]

  # Install packages.
  provisioner "shell" {
    name = "Install Packages"
    inline = [
      # Configure DNF to find the fastest mirror
      # and download packages in parallel; without
      # these options, some hosts will timeout their
      # package installations during cloud-init.
      "echo fastestmirror=True >> /etc/dnf/dnf.conf",
      "echo max_parallel_downloads=10 >> /etc/dnf/dnf.conf",

      # Register custom repositories.
      "dnf config-manager --add-repo https://pkg.cloudflare.com/cloudflared-ascii.repo",
      "dnf config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo",
      "dnf install -y epel-release",

      # Refresh repositories and packages.
      "dnf upgrade -y --refresh",

      # Install packages.
      "dnf install -y sudo fail2ban cloudflared docker-ce docker-ce-cli containerd.io docker-compose-plugin wget git git-lfs",

      # Cleanup.
      "dnf -y clean all && rm -rf /var/cache && df -h",
      "rm -rf /tmp/user-packages.txt",
    ]
  }

  # Configure security policies.
  provisioner "shell" {
    name = "Configure Firewalls"
    inline = [
      "timedatectl set-timezone 'America/New_York'",

      # Disallow password and root login via SSH.
      "sed -i -E 's/#?\\s*PasswordAuthentication\\s*.+$/PasswordAuthentication no/' /etc/ssh/sshd_config",
      "sed -i -E 's/#?\\s*PermitRootLogin\\s*.+$/PermitRootLogin no/' /etc/ssh/sshd_config",
      "sed -i -E 's/#?\\s*PermitEmptyPasswords\\s*.+$/PermitEmptyPasswords no/' /etc/ssh/sshd_config",
      <<-EOF
      cat <<eof > /etc/ssh/sshd_config.d/workbench.conf
      PasswordAuthentication no
      PermitRootLogin no
      PermitEmptyPasswords no
      eof
      EOF
      ,

      # Activate firewall.
      "systemctl enable --now firewalld",

      # Disallow most ingress traffic in the public zone;
      # cloudflared will control public ingress.
      "firewall-cmd --permanent --zone=public --remove-service=ssh",
      "firewall-cmd --permanent --zone=public --remove-service=http",
      "firewall-cmd --permanent --zone=public --remove-service=https",
      "firewall-cmd --permanent --zone=public --remove-service=cockpit",

      # Allow SSH ingress traffic on the internal zone from private IPs.
      "firewall-cmd --permanent --zone=trusted --add-service=ssh",
      "firewall-cmd --permanent --zone=trusted --add-source=10.0.0.0/24",

      # Activate fail2ban.
      "systemctl enable --now fail2ban",

      # Configure fail2ban.
      <<-EOF
      cat <<eof > /etc/fail2ban/jail.local
      [DEFAULT]
      bantime = 3600
      [sshd]
      enabled = true
      eof
      EOF
      ,
    ]
  }

  # Upload customized code-server assets.
  provisioner "shell" {
    inline = ["mkdir -p /tmp/workbench/assets"]
  }
  provisioner "file" {
    source      = "assets/"
    destination = "/tmp/workbench/assets"
  }

  # Install code server.
  provisioner "shell" {
    name = "Install code-server"
    inline = [
      "cd /tmp/workbench/assets",
      "wget https://github.com/coder/code-server/releases/download/v${var.code_server_version}/code-server-${var.code_server_version}-${var.code_server_arch}.rpm",
      "rpm -K code-server-${var.code_server_version}-${var.code_server_arch}.rpm",
      "dnf install -y ./code-server-${var.code_server_version}-${var.code_server_arch}.rpm",
      "rm code-server-${var.code_server_version}-${var.code_server_arch}.rpm",
    ]
  }

  # Customize code-server.
  provisioner "shell" {
    inline = [
      "cd /tmp/workbench/assets",
      "sh patch-code-server.sh",
      "cd /",
      "rm -rf /tmp/workbench"
    ]
  }

  # Enable systemd services.
  provisioner "shell" {
    name = "Enable systemd Services"
    inline = [
      "systemctl daemon-reload",
      "systemctl enable docker",
    ]
  }
}
