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

# ============================================
# MySQL променливи (за Docker контейнера)
# ============================================
variable "mysql_database_name" {
  type        = string
  description = "MySQL database name"
  default     = "nextcloud"
}

variable "mysql_user" {
  type        = string
  description = "MySQL user"
  default     = "nextclouduser"
}

variable "mysql_password" {
  type        = string
  description = "MySQL password"
  sensitive   = true
  default     = "MyP@ssw0rd123!"
}

variable "tags" {
  type        = map(string)
  description = "Tags to apply to resources"
  default = {
    environment = "development"
    managed_by  = "terraform"
  }
}