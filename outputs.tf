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

output "mysql_server_name" {
  value = azurerm_mysql_server.mysql.name
}

output "mysql_database_name" {
  value = azurerm_mysql_database.mysql_db.name
}

output "mysql_fqdn" {
  value = azurerm_mysql_server.mysql.fqdn
}

output "mysql_admin_username" {
  value = var.mysql_admin_username
  sensitive = true
}