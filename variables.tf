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

variable "tags" {
  type        = map(string)
  description = "Tags to apply to resources"
  default = {
    environment = "development"
    managed_by  = "terraform"
  }
}