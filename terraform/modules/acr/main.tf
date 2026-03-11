locals {
<<<<<<< HEAD
  name = var.name_override != "" ? var.name_override : replace("${var.name_prefix}acr", "-", "")
=======
  name = var.name_override != "" ?
    var.name_override :
    replace("${var.name_prefix}acr", "-", "")
>>>>>>> origin/main
}

resource "azurerm_container_registry" "acr" {
  name                = local.name
  resource_group_name = var.rg_name
  location            = var.location
  sku                 = var.sku
  admin_enabled       = false
}

output "name" {
  value = azurerm_container_registry.acr.name
}

output "login_server" {
  value = azurerm_container_registry.acr.login_server
}

output "acr_id" {
  value = azurerm_container_registry.acr.id
}