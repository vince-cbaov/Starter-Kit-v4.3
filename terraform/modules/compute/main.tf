# Docker VM
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

resource "azurerm_network_security_group" "docker_nsg" {
  count               = var.enable_docker_vm ? 1 : 0
  name                = "${var.name_prefix}-docker-nsg"
  location            = var.location
  resource_group_name = var.rg_name

  # ⚠ Insecure: Docker’s plaintext API on 2375
  security_rule {
    name                       = "docker-remote"
    priority                   = 1001
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "2375"
    source_address_prefixes    = "Internet"   # or "0.0.0.0/0"
    destination_address_prefix = "*"
  }
}

resource "azurerm_network_interface_security_group_association" "docker_nsg_assoc" {
  count                     = var.enable_docker_vm ? 1 : 0
  network_interface_id      = azurerm_network_interface.docker_nic[0].id
  network_security_group_id = azurerm_network_security_group.docker_nsg[0].id
}

resource "azurerm_linux_virtual_machine" "docker" {
  count               = var.enable_docker_vm ? 1 : 0
  name                = "${var.name_prefix}-docker"
  location            = var.location
  resource_group_name = var.rg_name
  size                = "Standard_B2s"
  admin_username      = var.admin_username

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
}

output "docker_public_ip" {
  value = try(azurerm_public_ip.docker_pip[0].ip_address, null)
}

# ---------------------------
# Jenkins VM (optional)
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

resource "azurerm_network_security_group" "jenkins_nsg" {
  count               = var.create_vms ? 1 : 0
  name                = "${var.name_prefix}-jenkins-nsg"
  location            = var.location
  resource_group_name = var.rg_name

  # SSH
  security_rule {
    name                       = "ssh"
    priority                   = 1001
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefixes    = "Internet"   # or "0.0.0.0/0"
    destination_address_prefix = "*"
  }

  # Jenkins UI (8080)
  security_rule {
    name                       = "jenkins-ui"
    priority                   = 1002
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "8080"
    source_address_prefixes    = "Internet"   # or "0.0.0.0/0"
    destination_address_prefix = "*"
  }
}

resource "azurerm_network_interface_security_group_association" "jenkins_nsg_assoc" {
  count                     = var.create_vms ? 1 : 0
  network_interface_id      = azurerm_network_interface.jenkins_nic[0].id
  network_security_group_id = azurerm_network_security_group.jenkins_nsg[0].id
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
}

output "jenkins_public_ip" {
  value = try(azurerm_public_ip.jenkins_pip[0].ip_address, null)
}
