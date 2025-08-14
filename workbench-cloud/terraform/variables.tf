# User account configurations.
variable "user_name" {
  type = string
}

variable "user_email" {
  type = string
}

# Network configurations.
variable "cf_api_token" {
  type      = string
  sensitive = true
}

variable "cf_account_id" {
  type = string
}

variable "cf_team_name" {
  type = string
}

variable "cf_policy_id" {
  type = string
}

variable "cf_app_domain" {
  type = string
}

variable "cf_app_subdomain" {
  type = string
}

# Virtual machine configurations.
variable "hetzner_api_token" {
  type      = string
  sensitive = true
}

variable "workbench_image_name" {
  type    = string
  default = "workbench"
}

variable "hetzner_datacenter" {
  type        = string
  default     = "hel1"
  description = "The Hetzner datacenter to deploy to. Examples: ash, nbg1, hel1"
}

variable "hetzner_region" {
  type        = string
  default     = "eu-central"
  description = "The Hetzner network region the VM will connect to. Examples: us-east or eu-central"
}

variable "hetzner_server_class" {
  type        = string
  default     = "cax21"
  description = "The Hetzner server class to deploy. Examples: cpx11 (AMD) or cax11 (ARM Ampere)"
}