variable "name" {
  type = string
}

variable "location" {
  type = string
}

resource "azurerm_resource_group" "rg" {
  name     = var.name
  location = var.location
}

variable "name" {
  type = string
}

variable "location" {
  type = string
}
