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
  }
}

# Obtain Cloudflare Zone ID from Account ID.
data "cloudflare_zones" "cloudflare_zone" {
  filter {
    account_id = var.cf_account_id
    status     = "active"
    name       = var.cf_app_domain
  }
}
locals {
  cloudflare_zone_id = data.cloudflare_zones.cloudflare_zone.zones[0].id
}

# Provision 64-character token for the Cloudflare tunnel.
resource "random_password" "cloudflare_tunnel_secret" {
  length = 64
}

# Provision default access policy for the application.
resource "cloudflare_access_policy" "workbench_app_policy" {
  account_id = var.cf_account_id
  name       = "Default (Allow ${var.user_email})"
  decision   = "allow"

  include {
    email = ["${var.user_email}"]
  }

  require {
    email = ["${var.user_email}"]
  }
}

# Provision Cloudflare access application for the tunnel.
resource "cloudflare_access_application" "workbench_app" {
  zone_id                   = local.cloudflare_zone_id
  name                      = "${var.workbench_name}-access-app"
  domain                    = "${var.cf_app_subdomain}.${var.cf_app_domain}"
  type                      = "self_hosted"
  session_duration          = "24h"
  auto_redirect_to_identity = false

  # Link the application to the policy we created above.
  policies = [cloudflare_access_policy.workbench_app_policy.id]
}

# Provision cloudflare tunnel.
resource "cloudflare_tunnel" "workbench_tunnel" {
  account_id = var.cf_account_id
  name       = "${var.workbench_name}-tunnel"
  secret     = base64sha256(random_password.cloudflare_tunnel_secret.result)
}

# Provision CNAME record (HTTP path) routing
# traffic to the tunnel.
resource "cloudflare_record" "workbench_tunnel_record" {
  zone_id = local.cloudflare_zone_id
  name    = var.cf_app_subdomain
  value   = cloudflare_tunnel.workbench_tunnel.cname
  type    = "CNAME"
  proxied = true
}

# Configure cloudflare tunnel.
resource "cloudflare_tunnel_config" "workbench_tunnel_config" {
  account_id = var.cf_account_id
  tunnel_id  = cloudflare_tunnel.workbench_tunnel.id
  config {

    # Route traffic from the  tunnel into the local
    # code-server service listening on port 31545.
    ingress_rule {
      hostname = cloudflare_record.workbench_tunnel_record.hostname
      service  = "http://localhost:31545"

      # Require access.
      origin_request {
        access {
          required  = true
          team_name = var.cf_team_name
          aud_tag   = [cloudflare_access_application.workbench_app.aud]
        }
      }
    }

    # Default rule will return a 404 to clients
    # if no other rules match.
    ingress_rule {
      service = "http_status:404"
    }
  }
}