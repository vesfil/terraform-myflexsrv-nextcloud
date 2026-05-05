# ============================================
# Outputs
# ============================================
output "web_app_name" {
  description = "The name of the deployed web app"
  value       = azurerm_linux_web_app.alwa.name
}

output "resource_group_name" {
  description = "The name of the resource group"
  value       = azurerm_resource_group.arg.name
}

output "random_suffix" {
  description = "The random suffix used for resources"
  value       = random_integer.ri.result
}

output "mysql_server_name" {
  description = "The name of the MySQL server"
  value       = azurerm_mysql_flexible_server.mysql.name
}

output "mysql_database_name" {
  description = "The name of the MySQL database"
  value       = azurerm_mysql_flexible_database.mysql_db.name
}

output "mysql_fqdn" {
  description = "The FQDN of the MySQL server"
  value       = azurerm_mysql_flexible_server.mysql.fqdn
}