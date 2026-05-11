variable "subscription_id" {
  type = string
}

variable "location" {
  type    = string
  default = "swedencentral"
}

variable "resource_group_name" {
  type    = string
  default = "rg-nextcloud"
}

variable "mysql_admin_user" {
  type = string
}

variable "mysql_admin_password" {
  type      = string
  sensitive = true
}

variable "mysql_database_name" {
  type    = string
  default = "nextcloud"
}

variable "nextcloud_admin_user" {
  type = string
}

variable "nextcloud_admin_password" {
  type      = string
  sensitive = true
}

variable "environment_suffix" {
  type = string
}

variable "tags" {
  type = map(string)

  default = {
    environment = "production"
    managed_by  = "terraform"
    app         = "nextcloud"
  }
}