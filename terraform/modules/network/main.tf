resource "azurerm_virtual_network" "vnet" {
  name                = "${var.name_prefix}-vnet"
  location            = var.location
  resource_group_name = var.rg_name

  address_space = ["10.10.0.0/16"]
}

resource "azurerm_subnet" "subnet_app" {
  name                 = "app"
  resource_group_name  = var.rg_name
  virtual_network_name = azurerm_virtual_network.vnet.name

  address_prefixes = ["10.10.1.0/24"]
}

# ---------------------------------------
# NSG REMOVED – this was causing the issue
# ---------------------------------------

# Old block removed:
#
# resource "azurerm_network_security_group" "shared_nsg" {
#   name = "${var.name_prefix}-shared-nsg"
#   ...
# }

# (No NSG here anymore; compute module owns the one NSG: sk-dev-nsg)