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

# ---------------------------------
# Shared NSG for workload NICs
# (not associated to the subnet here)
# ---------------------------------
resource "azurerm_network_security_group" "shared_nsg" {
  name                = "${var.name_prefix}-shared-nsg"
  location            = var.location
  resource_group_name = var.rg_name

  # SSH (22) - restrict to trusted CIDR
  security_rule {
    name                       = "ssh"
    priority                   = 1001
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefixes    = [var.trusted_cidr]
    destination_address_prefix = "*"
  }

  # Jenkins UI (8080) - restrict to trusted CIDR (recommended)
  # If you must open public, change to ["0.0.0.0/0"] and reconsider security posture.
  security_rule {
    name                       = "jenkins-ui"
    priority                   = 1002
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "8080"
    source_address_prefixes    = [var.trusted_cidr]
    destination_address_prefix = "*"
  }

  # Docker remote TLS (2376) - restrict to trusted CIDR
  security_rule {
    name                       = "docker-remote-tls"
    priority                   = 1003
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "2376"
    source_address_prefixes    = [var.trusted_cidr]
    destination_address_prefix = "*"
  }
}

# (Intentionally NO subnet association here; NIC-level association happens in modules/compute)