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

variable "ssh_public_key" {
  type    = string
  default = ""
}

variable "acr_name" {
  type    = string
  default = "starterkitacr"
}

variable "sp_app_id" {
  type    = string
  default = "<PUT-YOUR-SP-APP-ID-HERE>"
}

variable "sp_secret" {
  type    = string
  default = "<PUT-YOUR-SP-SECRET-HERE>"
}

variable "tenant_id" {
  type    = string
  default = "<PUT-YOUR-TENANT-ID-HERE>"
}

variable "create_vms" {
  type    = bool
  default = true
}

variable "enable_docker_vm" {
  type    = bool
  default = true
}

variable "sp_object_id" {
  type        = string
  description = "Object ID of the service principal"
  default     = "<PUT-YOUR-SP-OBJECT-ID-HERE>"
}
