variable "rg_name" {
  type        = string
  description = "Resource group that will contain the Key Vault"
}

variable "location" {
  type        = string
  description = "Azure region for the Key Vault"
}

variable "name_prefix" {
  type        = string
  description = "Prefix used for naming resources"
}

variable "tenant_id" {
  type        = string
  description = "Tenant ID for the Key Vault"
}

variable "sp_object_id" {
  type        = string
  description = "Object ID of the identity running Terraform"
}

variable "ssh_private_key" {
  type        = string
  description = "SSH private key stored in Key Vault"
}

variable "secrets" {
  type        = map(string)
  description = "Map of secrets to create in the Key Vault"
}

variable "access_object_ids" {
  type        = list(string)
  default     = []
  description = "Optional list of identities for Key Vault read access"
}