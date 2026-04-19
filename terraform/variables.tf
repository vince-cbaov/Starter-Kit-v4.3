############################################
# ROOT VARIABLES — FINAL CLEAN VERSION
############################################

# ---------------------------
# Global Settings
# ---------------------------
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

variable "subscription_id" {
  type        = string
  description = "Azure Subscription ID for role assignment scope"
}

# ---------------------------
# Compute / VM Settings
# ---------------------------
variable "admin_username" {
  type        = string
  description = "VM administrator username"
}

variable "ssh_public_key" {
  type        = string
  description = "SSH public key for Jenkins VM admin access"
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

# ---------------------------
# ACR
# ---------------------------
variable "acr_name" {
  type        = string
  description = "Override ACR name (optional)"
  default     = null
}

# ---------------------------
# Key Vault
# ---------------------------
variable "ssh_private_key" {
  type        = string
  description = "Optional SSH private key to store in Key Vault"
  default     = null
}

variable "secrets" {
  type        = map(string)
  description = "Map of Key Vault secrets to create"
  default     = {}
}

variable "access_object_ids" {
  type        = list(string)
  description = "Additional identities to grant Key Vault data-plane access"
  default     = []
}

variable "rbac_wait_seconds" {
  type        = number
  description = "Wait time for RBAC propagation before writing secrets"
  default     = 60
}

# ---------------------------
# AKS
# ---------------------------
variable "cluster_name" {
  type        = string
  description = "Name of the AKS cluster to create"
}

variable "dns_prefix" {
  type        = string
  description = "DNS prefix for the AKS cluster"
}

variable "workload_identity_client_id" {
  description = "Client ID of the Azure AD application to use for AKS Workload Identity"
  type        = string
}