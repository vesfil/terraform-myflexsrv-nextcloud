output "web_app_name" {
  value = azurerm_linux_web_app.alwa.name
}

output "resource_group_name" {
  value = azurerm_resource_group.arg.name
}

output "random_suffix" {
  value = random_integer.ri.result
}

output "sql_server_name" {
  value = azurerm_mssql_server.sqlserver.name
}

output "sql_database_name" {
  value = azurerm_mssql_database.database.name
}