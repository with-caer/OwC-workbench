variable "workbench_image_name" {
  type    = string
  default = "workbench"
}

variable "hetzner_api_token" {
  type      = string
  sensitive = true
}

variable "hetzner_server_location" {
  type        = string
  default     = "hel1"
  description = "The Hetzner datacenter to build in. Examples: ash, nbg1, hel1"
}

variable "hetzner_server_class" {
  type        = string
  default     = "cax11"
  description = "The Hetzner lowest-tier server class the workbench image will be compatible with. Examples: cpx11 (AMD) or cax11 (ARM Ampere)"
}

variable "hetzner_server_class_build" {
  type        = string
  default     = "cax41"
  description = "The Hetzner server class the workbench image will be built on. Examples: cpx51 (AMD) or cax41 (ARM Ampere)"
}

variable "code_server_version" {
  type        = string
  default     = "4.99.3"
  description = "The version of code-server to install. Example: 4.89.1"
}

variable "code_server_arch" {
  type        = string
  default     = "arm64"
  description = "The architecture to compile code-server for. Examples: amd64 or arm64"
}