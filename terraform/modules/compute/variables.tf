variable "create_vms" {
  description = "Create Jenkins VM"
  type        = bool
  default     = false
}

variable "enable_docker_vm" {
  description = "Create Docker VM"
  type        = bool
  default     = false
}

variable "rg_name" {
  type = string
}

variable "location" {
  type = string
}

variable "name_prefix" {
  type = string
}

variable "subnet_id" {
  type = string
}

variable "admin_username" {
  type    = string
  default = "vinadmin"
}

variable "ssh_public_key" {
  type = string
}
