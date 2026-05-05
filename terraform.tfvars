resource_group_name   = "rg-nextcloud"
location              = "switzerlandnorth"
app_service_plan_name = "asp-nextcloud"
web_app_name          = "nextcloud"

# MySQL настройки
mysql_server_name     = "mysql-nextcloud"
mysql_admin_username  = "mysqladmin"
mysql_admin_password  = "MyP@ssw0rd123!"
mysql_database_name   = "nextclouddb"

firewall_rule_name    = "AllowAllAzureServices"
github_repository_url = "https://github.com/vesfil/terraform-myflexsrv-nextcloud"

tags = {
  environment = "development"
  managed_by  = "terraform"
}