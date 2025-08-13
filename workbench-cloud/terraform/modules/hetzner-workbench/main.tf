terraform {
  required_version = ">= 0.13"

  required_providers {
    hcloud = {
      source  = "hetznercloud/hcloud"
      version = "~> 1.47"
    }
  }
}

# Provision the workbench private network.
resource "hcloud_network" "workbench_network" {
  name     = "${var.workbench_name}-network"
  ip_range = "10.0.0.0/16"
  labels = {
    "workbench/name" = var.workbench_name
  }
}

resource "hcloud_network_subnet" "workbench_subnet" {
  type         = "cloud"
  network_id   = hcloud_network.workbench_network.id
  network_zone = var.hetzner_region
  ip_range     = "10.0.0.0/24"
}

# Get the latest workbench VM snapshot.
data "hcloud_image" "workbench_snapshot" {
  with_selector = "workbench/image==${var.workbench_image_name}"
  most_recent   = true

  # ARM images require additional specification:
  # https://github.com/hetznercloud/terraform-provider-hcloud/issues/762#issuecomment-1746205223
  with_architecture = "arm"
}

# Provision a new SSH key for the workbench VM.
# The key is never actually usabe, since we fully
# disable root login over SSH; we only create this
# key so that Hetzner doesn't try to assign a
# default root password and _email_ it to us.
resource "tls_private_key" "workbench_ephemeral_ssh_key" {
  algorithm = "ED25519"
}
resource "hcloud_ssh_key" "workbench_ephemeral_ssh_key" {
  name       = "${var.workbench_name}-ephemeral-key"
  public_key = tls_private_key.workbench_ephemeral_ssh_key.public_key_openssh
  labels = {
    "workbench/name" = var.workbench_name
  }
}

# Provision the workbench VM.
resource "hcloud_server" "workbench" {
  name        = var.workbench_name
  image       = data.hcloud_image.workbench_snapshot.id
  server_type = var.hetzner_server_class
  location    = var.hetzner_datacenter
  ssh_keys    = [hcloud_ssh_key.workbench_ephemeral_ssh_key.name]
  user_data = templatefile("${path.module}/workbench.cloud-init.tftpl.sh", {
    # Cloudflare configuration.
    cloudflare_tunnel_token = var.cf_tunnel_token

    # User configuration.
    user_name         = var.user_name,
    user_email        = var.user_email,
    user_setup_script = file("${path.module}/user-setup.sh"),
  })

  network {
    network_id = hcloud_network.workbench_network.id
    ip         = "10.0.0.3"
  }

  public_net {

    # On Hetzner, a public IPv4 address must
    # be assigned, or else the server won't
    # be able to create outgoing connections
    # (e.g., for downloading packages).
    ipv4_enabled = true
    ipv6_enabled = false
  }

  labels = {
    "workbench/name" = var.workbench_name
  }
}