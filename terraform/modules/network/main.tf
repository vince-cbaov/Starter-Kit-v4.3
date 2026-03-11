resource "azurerm_virtual_network" "vnet" {
  name                = "${var.name_prefix}-vnet"
  location            = var.location
  resource_group_name = var.rg_name

<<<<<<< HEAD
  address_space = ["10.10.0.0/16"]
=======
  address_space = [
    "10.10.0.0/16"
  ]
>>>>>>> origin/main
}

resource "azurerm_subnet" "subnet_app" {
  name                 = "app"
  resource_group_name  = var.rg_name
  virtual_network_name = azurerm_virtual_network.vnet.name
<<<<<<< HEAD
  address_prefixes     = ["10.10.1.0/24"]
=======

  address_prefixes = [
    "10.10.1.0/24"
  ]
>>>>>>> origin/main
}

output "subnet_id" {
  value = azurerm_subnet.subnet_app.id
}