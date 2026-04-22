variable "resource_group_name" {
  type        = string
  description = "Resource group that will contain the Key Vault."
}

variable "location" {
  type        = string
  description = "Azure region for the Key Vault."
}

variable "name_prefix" {
  type        = string
  description = "Prefix used for naming resources."
}

variable "create_key_vault" {
  type        = bool
  default     = true
  description = "Create a Key Vault if true; otherwise use key_vault_id."
}

variable "key_vault_id" {
  type        = string
  default     = null
  description = "Existing Key Vault ID when create_key_vault = false."
}

variable "secrets" {
  type        = map(string)
  default     = {}
  sensitive   = true
  description = "Map of secrets to seed into Key Vault."
}

variable "ssh_private_key" {
  type        = string
  default     = null
  sensitive   = true
  description = "Optional SSH private key to store in Key Vault."
}

variable "access_object_ids" {
  type        = list(string)
  default     = []
  description = "Optional identities granted Key Vault Secrets User."
}

variable "rbac_wait_seconds" {
  type        = number
  default     = 60
  description = "Seconds to wait for RBAC propagation."
}

# THIS IS THE ONLY IDENTITY INPUT NOW (OIDC)
variable "workload_identity_principal_id" {
  type        = string
  description = "Principal ID of the AKS workload identity."
}
