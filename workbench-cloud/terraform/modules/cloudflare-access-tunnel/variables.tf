# User configuration.
variable "user_email" {
  type = string
}

variable "workbench_name" {
  type = string
}

# Network (Cloudflare) configuration.
variable "cf_account_id" {
  type = string
}

variable "cf_team_name" {
  type        = string
}

variable "cf_app_domain" {
  type        = string
}

variable "cf_app_subdomain" {
  type        = string
}