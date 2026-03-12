variable "location" {
  type    = string
  default = "northeurope"
}

variable "name_prefix" {
  type    = string
  default = "sk-dev"
}

variable "admin_username" {
  type    = string
  default = "vinadmin"
}

variable "ssh_public_key" {
  type    = string
  default = ""
}

variable "acr_name" {
  type    = string
  default = "starterkitacr"
}

variable "create_vms" {
  type    = bool
  default = true
}

variable "enable_docker_vm" {
  type    = bool
  default = true
}
