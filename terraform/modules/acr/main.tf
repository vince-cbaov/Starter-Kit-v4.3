# modules/acr/main.tf
locals {
  # Safe ACR name (lowercase, remove dashes). Ensure length 5-50 in your naming scheme.
  base_name = var.name_override != "" ? var.name_override : replace("${var.name_prefix}acr", "-", "")
  name      = lower(local.base_name)
}

resource "azurerm_container_registry" "acr" {
  name                = local.name
  resource_group_name = var.rg_name
  location            = var.location
  sku                 = var.sku
  admin_enabled       = false
}
