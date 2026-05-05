resource_group_name   = "rg-nextcloud"
location              = "switzerlandnorth"
app_service_plan_name = "asp-nextcloud"

tags = {
  environment = "development"
  managed_by  = "terraform"
}