variable "rg_name" {
  type = string
}

variable "location" {
  type = string
}

variable "cluster_name" {
  type = string
}
variable "dns_prefix" {
  type = string
}
variable "name_prefix" {
  type = string
}

variable "node_vm_size" {
  type = string
}

variable "resource_group_name" {
  type = string
}

variable "azurerm_user_assigned_identity" {
  type = object({
    name                = string
    resource_group_name = string
    location            = string
  })
}