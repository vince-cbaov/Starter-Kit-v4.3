# ---------------------------
# Docker VM
# ---------------------------
resource "azurerm_public_ip" "docker_pip" {
  count               = var.enable_docker_vm ? 1 : 0
  name                = "${var.name_prefix}-docker-pip"
  location            = var.location
  resource_group_name = var.rg_name
  allocation_method   = "Static"
  sku                 = "Standard"
}

resource "azurerm_network_interface" "docker_nic" {
  count               = var.enable_docker_vm ? 1 : 0
  name                = "${var.name_prefix}-docker-nic"
  location            = var.location
  resource_group_name = var.rg_name

  ip_configuration {
    name                          = "ipcfg"
    subnet_id                     = var.subnet_id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.docker_pip[0].id
  }
}

# ---------------------------
# Jenkins VM
# ---------------------------
resource "azurerm_public_ip" "jenkins_pip" {
  count               = var.create_vms ? 1 : 0
  name                = "${var.name_prefix}-jenkins-pip"
  location            = var.location
  resource_group_name = var.rg_name
  allocation_method   = "Static"
  sku                 = "Standard"
}

resource "azurerm_network_interface" "jenkins_nic" {
  count               = var.create_vms ? 1 : 0
  name                = "${var.name_prefix}-jenkins-nic"
  location            = var.location
  resource_group_name = var.rg_name

  ip_configuration {
    name                          = "ipcfg"
    subnet_id                     = var.subnet_id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.jenkins_pip[0].id
  }
}

# ---------------------------------
# Shared NSG (create if not provided)
# ---------------------------------
locals {
  shared_nsg_name = var.nsg_name != null ? var.nsg_name : "${var.name_prefix}-shared-nsg"
}

resource "azurerm_network_security_group" "shared_nsg" {
  count               = var.nsg_id == null && var.create_nsg ? 1 : 0
  name                = local.shared_nsg_name
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
  # If you must open to internet, change to ["0.0.0.0/0"] or front with a reverse proxy.
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

# Which NSG ID to use: existing or created
locals {
  effective_nsg_id = var.nsg_id != null ? var.nsg_id : try(azurerm_network_security_group.shared_nsg[0].id, null)
}

# Associate the same NSG to both NICs (if VM exists and NSG is available)
resource "azurerm_network_interface_security_group_association" "docker_nsg_assoc" {
  count                     = var.enable_docker_vm && local.effective_nsg_id != null ? 1 : 0
  network_interface_id      = azurerm_network_interface.docker_nic[0].id
  network_security_group_id = local.effective_nsg_id
}

resource "azurerm_network_interface_security_group_association" "jenkins_nsg_assoc" {
  count                     = var.create_vms && local.effective_nsg_id != null ? 1 : 0
  network_interface_id      = azurerm_network_interface.jenkins_nic[0].id
  network_security_group_id = local.effective_nsg_id
}

# ---------------------------
# VMs
# ---------------------------
resource "azurerm_linux_virtual_machine" "docker" {
  count               = var.enable_docker_vm ? 1 : 0
  name                = "${var.name_prefix}-docker"
  location            = var.location
  resource_group_name = var.rg_name
  size                = "Standard_B2s"
  admin_username      = var.admin_username

  network_interface_ids = [azurerm_network_interface.docker_nic[0].id]

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts"
    version   = "latest"
  }

  admin_ssh_key {
    username   = var.admin_username
    public_key = var.ssh_public_key
  }
}

resource "azurerm_linux_virtual_machine" "jenkins" {
  count               = var.create_vms ? 1 : 0
  name                = "${var.name_prefix}-jenkins"
  location            = var.location
  resource_group_name = var.rg_name
  size                = "Standard_B2s"
  admin_username      = var.admin_username

  network_interface_ids = [azurerm_network_interface.jenkins_nic[0].id]

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts"
    version   = "latest"
  }

  admin_ssh_key {
    username   = var.admin_username
    public_key = var.ssh_public_key
  }
}

# ---------------------------
# Outputs
# ---------------------------
output "docker_public_ip" {
  value = try(azurerm_public_ip.docker_pip[0].ip_address, null)
}

output "jenkins_public_ip" {
  value = try(azurerm_public_ip.jenkins_pip[0].ip_address, null)
}

output "effective_nsg_id" {
  description = "NSG used by both NICs (existing or created)."
  value       = local.effective_nsg_id
}
