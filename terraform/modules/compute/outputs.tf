# ---------------------------
# Managed Identity Outputs
# ---------------------------
output "docker_vm_principal_id" {
  description = "Managed Identity principal ID of the Docker VM"
  value       = var.enable_docker_vm ? azurerm_linux_virtual_machine.docker[0].identity[0].principal_id : null
}

output "jenkins_vm_principal_id" {
  description = "Managed Identity principal ID of the Jenkins VM"
  value       = var.create_vms ? azurerm_linux_virtual_machine.jenkins[0].identity[0].principal_id : null
}

# ---------------------------
# Public IP Outputs
# ---------------------------
output "docker_public_ip" {
  description = "Public IP of the Docker VM (admin access only)"
  value       = try(azurerm_public_ip.docker_pip[0].ip_address, null)
}

output "jenkins_public_ip" {
  description = "Public IP of the Jenkins VM"
  value       = try(azurerm_public_ip.jenkins_pip[0].ip_address, null)
}

# ---------------------------
# Private IP Outputs
# ---------------------------
output "docker_private_ip" {
  description = "Private IP of Docker VM (used internally by Jenkins)"
  value       = var.enable_docker_vm ? azurerm_network_interface.docker_nic[0].private_ip_address : null
}

output "jenkins_private_ip" {
  description = "Private IP of Jenkins VM"
  value       = var.create_vms ? azurerm_network_interface.jenkins_nic[0].private_ip_address : null
}

# ---------------------------
# SSH Key Outputs (Sensitive)
# ---------------------------
output "jenkins_docker_private_key" {
  description = "Private SSH key for Jenkins to access Docker VM"
  value       = tls_private_key.jenkins_docker_ssh.private_key_openssh
  sensitive   = true
}

output "jenkins_docker_public_key" {
  description = "Public SSH key for Jenkins to access Docker VM"
  value       = tls_private_key.jenkins_docker_ssh.public_key_openssh
}

# ---------------------------
# Networking Outputs
# ---------------------------
output "effective_nsg_id" {
  description = "ID of the shared Network Security Group"
  value       = azurerm_network_security_group.shared_nsg.id
}