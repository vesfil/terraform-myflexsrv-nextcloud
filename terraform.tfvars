resource_group_name   = "rg-nextcloud"
location              = "switzerlandnorth"
app_service_plan_name = "asp-nextcloud"

mysql_database_name = "nextcloud"
mysql_user          = "nextclouduser"
mysql_password      = "MyP@ssw0rd123!"

tags = {
  environment = "development"
  managed_by  = "terraform"
}