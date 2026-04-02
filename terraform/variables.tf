############################################
# ROOT VARIABLES — Final Aligned Version
############################################

#
# Global Settings
#
variable "location" {
  type        = string
  description = "Azure region to deploy into"
  default     = "northeurope"
}

variable "name_prefix" {
  type        = string
  description = "Environment prefix (e.g., sk-dev, sk-prod)"
  default     = "sk-dev"
}

variable "trusted_cidr" {
  type        = string
  description = "CIDR allowed to access exposed services (NSG rules)"
}

#
# Compute / VM Settings
#
variable "admin_username" {
  type        = string
  description = "VM administrator username"
}

variable "ssh_public_key" {
  type        = string
  description = "SSH public key for VM login"
}

variable "create_vms" {
  type        = bool
  description = "Whether to create Jenkins VM"
  default     = true
}

variable "enable_docker_vm" {
  type        = bool
  description = "Whether to create Docker VM"
  default     = true
}

#
# ACR
#
variable "acr_name" {
  type        = string
  description = "Override ACR name (optional)"
  default     = null
}

#
# Key Vault + SP Settings
#
variable "sp_object_id" {
  type        = string
  description = "Object ID of the identity running Terraform (for KV secret writes)"
}

variable "ssh_private_key" {
  type        = string
  description = "Optional SSH private key to store in KV"
  default     = null
}

variable "secrets" {
  type        = map(string)
  description = "Map of Key Vault secrets to create"
  default     = {}
}

variable "access_object_ids" {
  type        = list(string)
  description = "Additional identities to grant KV data-plane access"
  default     = []
}

variable "rbac_wait_seconds" {
  type        = number
  description = "Wait time for RBAC propagation before writing secrets"
  default     = 60
}

variable "extra_role_assignments" {
  type = list(object({
    role_definition_name = string
    scope                = string
  }))
  description = "Optional extra management-plane RBAC assignments for the SP"
  default     = []
}

variable "tenant_id" {
  type        = string
  description = "Azure Tenant ID (for CSI driver configuration)"
}

variable "resource_group_name" {
  type        = string
  description = "Name of the resource group to create/use"

}

variable "cluster_name" {
  type        = string
  description = "Name of the AKS cluster to create"
}

variable "dns_prefix" {
  type        = string
  description = "DNS prefix for the AKS cluster"
}
