variable "rg_name" {
  type = string
}

variable "location" {
  type = string
}

variable "name_prefix" {
  type = string
}

variable "tenant_id" {
  type = string
}

variable "secrets" {
  type    = map(string)
  default = {}
}

variable "access_object_ids" {
  type    = list(string)
  default = []
}

variable "sp_object_id" {
  description = "Object ID of the service principal (principal_id) that runs Terraform"
  type        = string
}
