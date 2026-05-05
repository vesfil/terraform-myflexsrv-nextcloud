# ============================================
# Outputs
# ============================================
output "web_app_name" {
  value = azurerm_linux_web_app.alwa.name
}

output "resource_group_name" {
  value = azurerm_resource_group.arg.name
}

output "random_suffix" {
  value = random_integer.ri.result
}