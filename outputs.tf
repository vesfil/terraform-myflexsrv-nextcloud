output "nextcloud_url" {
  value = "https://${azurerm_linux_web_app.nextcloud.default_hostname}"
}

output "mysql_fqdn" {
  value = azurerm_mysql_flexible_server.mysql.fqdn
}

output "resource_group_name" {
  value = azurerm_resource_group.rg.name
}