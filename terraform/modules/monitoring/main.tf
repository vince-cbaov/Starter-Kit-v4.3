resource "azurerm_log_analytics_workspace" "law" {
  name                = "${var.name_prefix}-law"
  location            = var.location
  resource_group_name = var.rg_name
<<<<<<< HEAD
<<<<<<< HEAD

  sku                = "PerGB2018"
  retention_in_days  = 30
=======
  sku                 = "PerGB2018"
  retention_in_days   = 30
>>>>>>> origin/main
=======
  sku                 = "PerGB2018"
  retention_in_days   = 30
>>>>>>> origin/dev
}

output "law_id" {
  value = azurerm_log_analytics_workspace.law.id
}
