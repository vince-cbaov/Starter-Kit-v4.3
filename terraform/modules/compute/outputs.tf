output "docker_vm_principal_id" {
  value = var.enable_docker_vm ? azurerm_linux_virtual_machine.docker[0].identity[0].principal_id : null
}

output "docker_vm_public_ip" {
  description = "Public IP address of the Docker build server"
  value       = azurerm_public_ip.docker_public_ip.ip_address
}

output "jenkins_docker_private_key" {
  description = "Private SSH key for Jenkins to access Docker VM"
  value       = tls_private_key.jenkins_docker_ssh.private_key_openssh
  sensitive   = true
}

output "jenkins_docker_public_key" {
  description = "Public SSH key for Jenkins to access Docker VM"
  value       = tls_private_key.jenkins_docker_ssh.public_key_openssh
}

output "jenkins_vm_principal_id" {
  value = var.create_vms ? azurerm_linux_virtual_machine.jenkins[0].identity[0].principal_id : null
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