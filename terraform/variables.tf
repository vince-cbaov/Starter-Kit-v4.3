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
  type = string
  description = "SSH public key for admin access"
}

variable "sp_app_id" {
  type = string
  description = "Service Principal Application (client) ID"
}

variable "sp_secret" {
  type      = string
  sensitive = true
  description = "Service Principal client secret"
}

variable "tenant_id" {
  type = string
  description = "Azure AD Tenant ID"
}

variable "sp_object_id" {
  type = string
  description = "Object ID of the Service Principal"
}
