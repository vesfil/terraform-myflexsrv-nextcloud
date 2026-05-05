resource_group_name   = "rg-nextcloud"
location              = "switzerlandnorth"
app_service_plan_name = "asp-nextcloud"

sql_server_name     = "sql-nextcloud"
sql_admin_name      = "sqladmin"
sql_admin_password  = "MyP@ssw0rd123!"
sql_database_name   = "nextclouddb"

firewall_rule_name    = "AllowAllAzureServices"

tags = {
  environment = "development"
  managed_by  = "terraform"
}