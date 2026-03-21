variable "rg_name" {
  type        = string
  description = "Resource group that will contain the Key Vault (if created)."
}

variable "location" {
  type        = string
  description = "Azure region for the Key Vault (if created)."
}

variable "name_prefix" {
  type        = string
  description = "Prefix used for naming resources (e.g., myapp -> myappkv)."
}

variable "sp_display_name" {
  type        = string
  description = "Name of the Service Principal / Application."
}

variable "secret_end_date_relative" {
  type        = string
  default     = "8760h" # 1 year
  description = "Lifetime of the generated client secret."
}

variable "create_key_vault" {
  type        = bool
  default     = true
  description = "Create a Key Vault if true; otherwise use key_vault_id."
}

variable "key_vault_id" {
  type        = string
  default     = null
  description = "Existing Key Vault ID. Required when create_key_vault = false."
}

variable "sp_object_id" {
  type        = string
  description = "Object ID of the identity running Terraform (to grant Secrets Officer)."
}

variable "secrets" {
  type        = map(string)
  default     = {}
  description = "Map of additional secrets to create in Key Vault."
  sensitive   = true
}

variable "ssh_private_key" {
  type        = string
  default     = null
  description = "SSH private key to store in Key Vault as 'ssh-private-key'."
  sensitive   = true
}

variable "access_object_ids" {
  type        = list(string)
  default     = []
  description = "Optional list of identities to grant 'Key Vault Secrets User'."
}

variable "key_vault_name_override" {
  type        = string
  default     = null
  description = "Optional specific KV name (no dashes). If null, uses name_prefix."
}

variable "rbac_wait_seconds" {
  type        = number
  default     = 60
  description = "Seconds to wait for RBAC propagation before writing secrets."
}

# === Management-plane role assignment for the created Service Principal ===
variable "sp_role_assignment_scope" {
  type        = string
  description = "Scope (resource ID) at which to assign SP roles (subscription/RG/resource)."
}

variable "assign_contributor" {
  type        = bool
  default     = true
  description = "Grant the SP the 'Contributor' role at sp_role_assignment_scope."
}

variable "assign_user_access_admin" {
  type        = bool
  default     = true
  description = "Grant the SP the 'User Access Administrator' role at sp_role_assignment_scope."
}

variable "extra_role_assignments" {
  type = list(object({
    role_definition_name = string # e.g., 'Reader' or custom role name
    scope                = string # explicit scope for this extra role
  }))
  default     = []
  description = "Optional additional SP role assignments (role name + scope)."
}


# === Outputs from the module (for reference, not variables) ===
