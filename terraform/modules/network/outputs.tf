output "subnet_id" {
  value       = azurerm_subnet.subnet_app.id
  description = "ID of the workload subnet."
}
