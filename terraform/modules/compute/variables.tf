# ---------------------------
# VM Creation Toggles
# ---------------------------
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

# ---------------------------
# Core Infrastructure
# ---------------------------
variable "rg_name" {
  description = "Resource group name"
  type        = string
}

variable "location" {
  description = "Azure region"
  type        = string
}

variable "name_prefix" {
  description = "Prefix for resource names"
  type        = string
}

variable "subnet_id" {
  description = "Subnet ID for VM NICs"
  type        = string
}

# ---------------------------
# VM Access
# ---------------------------
variable "admin_username" {
  description = "Admin username for Linux VMs"
  type        = string
  default     = "vinadmin"
}

variable "ssh_public_key" {
  description = "Public SSH key for Jenkins VM admin access"
  type        = string
}

variable "trusted_cidr" {
  description = "Trusted CIDR allowed to access SSH/Jenkins UI (e.g. x.x.x.x/32)"
  type        = string
}

variable "user_assigned_identity_id" {
  description = "User Assigned Managed Identity ID for Jenkins VM"
  type        = string
}

# ---------------------------
# Key Vault Integration
# ---------------------------
variable "key_vault_id" {
  description = "ID of the Key Vault used to store generated secrets"
  type        = string
}

# ---------------------------
# NSG Handling (future‑proofed)
# ---------------------------
variable "nsg_id" {
  description = "Existing NSG ID to associate with NICs (optional)"
  type        = string
  default     = null
}

variable "create_nsg" {
  description = "Create a new NSG when nsg_id is null"
  type        = bool
  default     = true
}

variable "nsg_name" {
  description = "Override name for the created NSG"
  type        = string
  default     = null
}