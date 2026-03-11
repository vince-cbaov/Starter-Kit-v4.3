<<<<<<< HEAD
<<<<<<< HEAD
variable "name" {
  type = string
}

variable "location" {
  type = string
=======
resource "azurerm_resource_group" "rg" {
  name     = var.name
  location = var.location
=======
variable "name" {
  type = string
>>>>>>> 0b58b27ab7c0049cc96e4fa5d46b6d765ceee0e9
}

variable "location" {
  type = string
}
<<<<<<< HEAD

output "location" {
  value = azurerm_resource_group.rg.location
>>>>>>> origin/main
}
=======
>>>>>>> 0b58b27ab7c0049cc96e4fa5d46b6d765ceee0e9
