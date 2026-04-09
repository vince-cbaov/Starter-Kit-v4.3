output "docker_vm_principal_id" {
  value = var.enable_docker_vm ? azurerm_linux_virtual_machine.docker[0].identity[0].principal_id : null
}