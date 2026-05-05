variable "resource_group_name" {
  type        = string
  description = "Resource group name"
  default     = "rg-nextcloud"
}

variable "location" {
  type        = string
  description = "Azure region"
  default     = "switzerlandnorth"
}

variable "app_service_plan_name" {
  type        = string
  description = "App Service Plan name"
  default     = "asp-nextcloud"
}

variable "sql_server_name" {
  type        = string
  description = "SQL Server name"
  default     = "sql-nextcloud"
}

variable "sql_admin_name" {
  type        = string
  description = "SQL Server admin username"
  default     = "sqladmin"
}

variable "sql_admin_password" {
  type        = string
  description = "SQL Server admin password"
  sensitive   = true
  default     = "MyP@ssw0rd123!"
}

variable "sql_database_name" {
  type        = string
  description = "SQL Database name"
  default     = "nextclouddb"
}

variable "firewall_rule_name" {
  type        = string
  description = "Firewall rule name"
  default     = "AllowAllAzureServices"
}

variable "tags" {
  type        = map(string)
  description = "Tags to apply to resources"
  default = {
    environment = "development"
    managed_by  = "terraform"
  }
}