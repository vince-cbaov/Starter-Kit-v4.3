############################################
# ROOT VARIABLES — Option E2 (Terraform creates KV secrets)
############################################

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

variable "ssh_public_key" {
  description = "SSH public key for admin access"
  type        = string
}

# -------------------------
# FOR KEY VAULT MODULE
# -------------------------

variable "tenant_id" {
  description = "Azure AD Tenant ID"
  type        = string
}

variable "sp_object_id" {
  description = "Object ID of the identity running Terraform"
  type        = string
}

variable "ssh_private_key" {
  description = "Private SSH key to store in Key Vault"
  type        = string
}

variable "secrets" {
  description = <<EOT
Map of Key Vault secrets to create in Option E2.
Example:
secrets = {
  acr-sp-app-id = "value"
  acr-sp-secret = "value"
  tenant-id     = "value"
  acr-name      = "value"
}
EOT
  type = map(string)
}

# Optional list for additional KV access
variable "access_object_ids" {
  type        = list(string)
  default     = []
  description = "Optional extra identities to grant data-plane access to the Key Vault"
}