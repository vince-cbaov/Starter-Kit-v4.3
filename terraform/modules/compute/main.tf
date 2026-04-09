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
# Shared NSG - ALWAYS CREATED
# ---------------------------------
resource "azurerm_network_security_group" "shared_nsg" {
  name                = "sk-dev-nsg"
  location            = var.location
  resource_group_name = var.rg_name

  # SSH from Virtual Network (Jenkins → Docker)
  security_rule {
    name                       = "ssh-from-vnet"
    priority                   = 1000
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "VirtualNetwork"
    destination_address_prefix = "*"
  }

  # SSH from trusted public IP (admin access)
  security_rule {
    name                       = "ssh-admin"
    priority                   = 1001
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefixes    = [var.trusted_cidr]
    destination_address_prefix = "*"
  }

  # Jenkins UI (8080) – restricted
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
}

# ---------------------------------
# NIC → NSG Associations
# ---------------------------------
resource "azurerm_network_interface_security_group_association" "docker_nsg_assoc" {
  count                     = var.enable_docker_vm ? 1 : 0
  network_interface_id      = azurerm_network_interface.docker_nic[0].id
  network_security_group_id = azurerm_network_security_group.shared_nsg.id
}

resource "azurerm_network_interface_security_group_association" "jenkins_nsg_assoc" {
  count                     = var.create_vms ? 1 : 0
  network_interface_id      = azurerm_network_interface.jenkins_nic[0].id
  network_security_group_id = azurerm_network_security_group.shared_nsg.id
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

  identity {
    type = "SystemAssigned"
  }

  network_interface_ids = [
    azurerm_network_interface.docker_nic[0].id
  ]

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

  tags = {
    role       = "docker"
    managed_by = "terraform"
  }
}

resource "azurerm_linux_virtual_machine" "jenkins" {
  count               = var.create_vms ? 1 : 0
  name                = "${var.name_prefix}-jenkins"
  location            = var.location
  resource_group_name = var.rg_name
  size                = "Standard_B2s"
  admin_username      = var.admin_username

  network_interface_ids = [
    azurerm_network_interface.jenkins_nic[0].id
  ]

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

  tags = {
    role       = "jenkins"
    managed_by = "terraform"
  }
}

# ---------------------------
# Outputs
# ---------------------------
output "docker_public_ip" {
  description = "Public IP of the Docker VM (admin only)"
  value       = try(azurerm_public_ip.docker_pip[0].ip_address, null)
}

output "jenkins_public_ip" {
  description = "Public IP of the Jenkins VM"
  value       = try(azurerm_public_ip.jenkins_pip[0].ip_address, null)
}

output "docker_private_ip" {
  description = "Private IP of Docker VM (used by Jenkins)"
  value       = azurerm_network_interface.docker_nic[0].private_ip_address
}

output "jenkins_private_ip" {
  description = "Private IP of Jenkins VM"
  value       = azurerm_network_interface.jenkins_nic[0].private_ip_address
}

output "effective_nsg_id" {
  description = "ID of the shared NSG"
  value       = azurerm_network_security_group.shared_nsg.id
}
