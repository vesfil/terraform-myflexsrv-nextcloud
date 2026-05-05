variable "resource_group_name" {
  type        = string
  description = "Resource group name"
  default     = "rg-nextcloud"
}

variable "location" {
  type        = string
  description = "Azure region (must be F1-supported)"
  default     = "switzerlandnorth"
}

variable "app_service_plan_name" {
  type        = string
  description = "App Service Plan name"
  default     = "asp-nextcloud"
}

# ============================================
# MySQL променливи (Single Server - Basic план)
# ============================================
variable "mysql_server_name" {
  type        = string
  description = "MySQL server name"
  default     = "mysql-nextcloud"
}

variable "mysql_admin_username" {
  type        = string
  description = "MySQL admin username"
  default     = "mysqladmin"
}

variable "mysql_admin_password" {
  type        = string
  description = "MySQL admin password (must be at least 8 chars, containing uppercase, lowercase, numbers, special chars)"
  sensitive   = true
  default     = "MyP@ssw0rd123!"
}

variable "mysql_database_name" {
  type        = string
  description = "MySQL database name"
  default     = "nextclouddb"
}

# ============================================
# Общи променливи
# ============================================
variable "tags" {
  type        = map(string)
  description = "Tags to apply to resources"
  default = {
    environment = "development"
    managed_by  = "terraform"
  }
}