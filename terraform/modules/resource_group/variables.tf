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
}

output "name" {
  value = azurerm_resource_group.rg.name
}

output "location" {
  value = azurerm_resource_group.rg.location
>>>>>>> origin/main
}