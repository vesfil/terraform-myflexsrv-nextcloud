# ============================================================
# AZURE
# ============================================================
variable "subscription_id" {
  type        = string
  description = "Azure Subscription ID"
}

variable "resource_group_name" {
  type    = string
  default = "rg-nextcloud"
}

variable "location" {
  type    = string
  default = "swedencentral"
}

# ============================================================
# APP SERVICE
# ============================================================
variable "app_service_plan_name" {
  type    = string
  default = "asp-nextcloud"
}

# ============================================================
# MYSQL
# ============================================================
variable "mysql_database_name" {
  type    = string
  default = "nextcloud"
}

variable "mysql_admin_user" {
  type    = string
  default = "mysqladmin"
}

variable "mysql_admin_password" {
  type      = string
  sensitive = true
}

# ============================================================
# NEXTCLOUD
# ============================================================
variable "nextcloud_admin_user" {
  type    = string
  default = "admin"
}

variable "nextcloud_admin_password" {
  type      = string
  sensitive = true
}

# ============================================================
# TAGS
# ============================================================
variable "tags" {
  type = map(string)

  default = {
    environment = "production"
    managed_by  = "terraform"
    app         = "nextcloud"
  }
}