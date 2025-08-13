# User configuration.
variable "user_name" {
  type        = string
}

variable "user_email" {
  type = string
}

variable "workbench_name" {
  type = string
}

# Network (Cloudflare) configuration.
variable "cf_tunnel_token" {
  type = string
  sensitive = true
}

# VM (Hetzner) configuration.
variable "workbench_image_name" {
  type    = string
  default = "workbench"
  description = "The name of the workbench snapshot image to build VMs from."
}

variable "hetzner_datacenter" {
  type        = string
  default     = "ash"
  description = "The Hetzner datacenter to deploy VMs into. Examples: ash or nbg1"
}

variable "hetzner_region" {
  type        = string
  default     = "us-east"
  description = "The Hetzner region to deploy networks into. Examples: us-east or eu-central"
}

variable "hetzner_server_class" {
  type        = string
  default     = "cpx21"
  description = "The Hetzner server class to deploy. Examples: cpx11 (AMD) or cax11 (ARM Ampere)"
}