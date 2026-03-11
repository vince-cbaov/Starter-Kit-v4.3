resource "azurerm_virtual_network" "vnet" {
  name                = "${var.name_prefix}-vnet"
  location            = var.location
  resource_group_name = var.rg_name

<<<<<<< HEAD
<<<<<<< HEAD
  address_space = ["10.10.0.0/16"]
=======
  address_space = [
    "10.10.0.0/16"
  ]
>>>>>>> origin/main
=======
  address_space = ["10.10.0.0/16"]
>>>>>>> 0b58b27ab7c0049cc96e4fa5d46b6d765ceee0e9
}

resource "azurerm_subnet" "subnet_app" {
  name                 = "app"
  resource_group_name  = var.rg_name
  virtual_network_name = azurerm_virtual_network.vnet.name
<<<<<<< HEAD
<<<<<<< HEAD
  address_prefixes     = ["10.10.1.0/24"]
=======

  address_prefixes = [
    "10.10.1.0/24"
  ]
>>>>>>> origin/main
=======
  address_prefixes     = ["10.10.1.0/24"]
>>>>>>> 0b58b27ab7c0049cc96e4fa5d46b6d765ceee0e9
}

output "subnet_id" {
  value = azurerm_subnet.subnet_app.id
}
