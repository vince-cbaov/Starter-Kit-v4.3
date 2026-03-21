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

# Restrict exposed ports
variable "trusted_cidr" {
  description = "Your office/home IP in CIDR (e.g., 203.0.113.10/32)"
  type        = string
}

# --- NSG handling ---
# If you have an NSG from the network module, pass its ID here to reuse it.
variable "nsg_id" {
  type        = string
  default     = null
  description = "Existing NSG ID to associate with NICs. If null and create_nsg = true, a new NSG is created."
}

variable "create_nsg" {
  type        = bool
  default     = true
  description = "Create a new NSG when nsg_id is null."
}

variable "nsg_name" {
  type        = string
  default     = null
  description = "Override name for the created NSG. Default: <name_prefix>-shared-nsg"
}