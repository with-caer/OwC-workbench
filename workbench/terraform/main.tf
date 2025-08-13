terraform {
  required_version = ">= 0.13"

  required_providers {
    random = {
      source = "hashicorp/random"
    }

    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = "~> 4.0"
    }

    hcloud = {
      source  = "hetznercloud/hcloud"
      version = "~> 1.47"
    }
  }
}

provider "random" {}

provider "cloudflare" {
  api_token = var.cf_api_token
}

provider "hcloud" {
  token = var.hetzner_api_token
}

locals {
  workbench_name = "${var.hetzner_datacenter}-${var.cf_app_subdomain}"
}

# Provision Cloudflare tunnel with managed access.
module "cloudflare_access_tunnel" {
  source           = "./modules/cloudflare-access-tunnel"
  user_email       = var.user_email
  workbench_name   = local.workbench_name
  cf_account_id    = var.cf_account_id
  cf_team_name     = var.cf_team_name
  cf_app_domain    = var.cf_app_domain
  cf_app_subdomain = var.cf_app_subdomain
}

# Provision the workbench.
module "hetzner_workbench" {
  source               = "./modules/hetzner-workbench"
  user_name            = var.user_name
  user_email           = var.user_email
  workbench_name       = local.workbench_name
  cf_tunnel_token      = module.cloudflare_access_tunnel.cf_tunnel_token
  workbench_image_name = var.workbench_image_name
  hetzner_datacenter   = var.hetzner_datacenter
  hetzner_region       = var.hetzner_region
  hetzner_server_class = var.hetzner_server_class
}