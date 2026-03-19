variable "create_vms" {
  description = "Create Jenkins VM"
  type        = bool
  default     = true
}

variable "enable_docker_vm" {
  description = "Create Docker VM"
  type        = bool
  default     = true
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

# restrict exposed ports; default is open (keep your current behaviour)
variable "trusted_cidr" {
  description = "Your office/home IP in CIDR (e.g., 203.0.113.10/32)"
  type        = string
}