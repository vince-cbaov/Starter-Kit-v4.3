output "subnet_id" {
  value       = azurerm_subnet.subnet_app.id
  description = "ID of the workload subnet."
}

output "nsg_id" {
  description = "ID of the shared NSG for NIC associations."
  value       = azurerm_network_security_group.shared_nsg.id
}