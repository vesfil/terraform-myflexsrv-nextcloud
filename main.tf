terraform {
  required_version = ">= 1.5"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "4.66.0"
    }

    random = {
      source  = "hashicorp/random"
      version = "3.8.1"
    }
  }

  backend "azurerm" {
    resource_group_name  = "NextcloudSTRG"
    storage_account_name = "stnextcloud2026"
    container_name       = "nextcloudcontainer"
    key                  = "terraform.tfstate"
    use_azuread_auth     = true
  }
}

provider "azurerm" {
  features {}
  subscription_id = var.subscription_id
}

#resource "random_integer" "suffix" {
#  min = 100
#  max = 999
#}

#resource "azurerm_resource_group" "rg" {
#  name     = "rg-nextcloud-${var.suffix}"
#  location = var.location
#}

locals {
  suffix = var.environment_suffix
}
# =========================
# RESOURCE GROUP
# =========================
resource "azurerm_resource_group" "rg" {
  #name     = "${var.resource_group_name}-${random_integer.suffix.result}"
  name     = "rg-nextcloud-${local.suffix}"
  location = var.location
}

# =========================
# SERVICE PLAN
# =========================
resource "azurerm_service_plan" "plan" {
  #name                = "${var.app_service_plan_name}-${random_integer.suffix.result}"
  #name                = "asp-nextcloud-${var.suffix}"
  name                = "asp-nextcloud-${local.suffix}"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location

  os_type  = "Linux"
  sku_name = "B2"
}

# =========================
# MYSQL FLEXIBLE SERVER
# =========================
resource "azurerm_mysql_flexible_server" "mysql" {
  #name                = "mysql-nextcloud-${random_integer.suffix.result}"
  #name                = "mysql-nextcloud-${var.suffix}"
  name                = "mysql-nextcloud-${local.suffix}"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location

  administrator_login    = var.mysql_admin_user
  administrator_password = var.mysql_admin_password

  sku_name = "B_Standard_B1ms"
  version  = "8.0.21"

  storage {
    size_gb = 20
  }

  # 🔥 CRITICAL: TLS ENFORCED (Azure default anyway, but explicit)
  delegated_subnet_id = null

  tags = var.tags
}

# =========================
# DATABASE
# =========================
resource "azurerm_mysql_flexible_database" "db" {
  name = var.mysql_database_name
  #name                = "nextcloud-${var.suffix}"
  resource_group_name = azurerm_resource_group.rg.name
  server_name         = azurerm_mysql_flexible_server.mysql.name

  charset   = "utf8mb4"
  collation = "utf8mb4_unicode_ci"
}

# =========================
# FIREWALL
# =========================
resource "azurerm_mysql_flexible_server_firewall_rule" "allow_azure" {
  name                = "AllowAzure"
  resource_group_name = azurerm_resource_group.rg.name
  server_name         = azurerm_mysql_flexible_server.mysql.name

  start_ip_address = "0.0.0.0"
  end_ip_address   = "0.0.0.0"
}

# =========================
# NEXTCLOUD WEB APP
# =========================
resource "azurerm_linux_web_app" "nextcloud" {
  #name                = "nextcloud-${random_integer.suffix.result}"
  name                = "nextcloud-${local.suffix}"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location

  service_plan_id = azurerm_service_plan.plan.id
  https_only      = true

  site_config {
    always_on = true

    app_command_line = ""

    application_stack {
      docker_image_name = "nextcloud:30-apache"
    }

    # FIX: Azure requirement (must be present if used)
    health_check_path                 = "/status.php"
    health_check_eviction_time_in_min = 10
  }

  app_settings = {
    WEBSITES_ENABLE_APP_SERVICE_STORAGE = "true"
    WEBSITES_PORT                       = "80"
    WEBSITES_CONTAINER_START_TIME_LIMIT = "1800"

    NEXTCLOUD_ADMIN_USER     = var.nextcloud_admin_user
    NEXTCLOUD_ADMIN_PASSWORD = var.nextcloud_admin_password
    #NEXTCLOUD_TRUSTED_DOMAINS = "nextcloud-${random_integer.suffix.result}.azurewebsites.net"
    NEXTCLOUD_TRUSTED_DOMAINS = "nextcloud-${local.suffix}.azurewebsites.net"

    # DB
    MYSQL_HOST     = azurerm_mysql_flexible_server.mysql.fqdn
    MYSQL_DATABASE = azurerm_mysql_flexible_database.db.name
    MYSQL_USER     = var.mysql_admin_user
    MYSQL_PASSWORD = var.mysql_admin_password

    # 🔥 CRITICAL FIX FOR YOUR ERROR
    MYSQL_ATTR_SSL_CA  = "/etc/ssl/certs/ca-certificates.crt"
    MYSQL_SSL_MODE     = "required"
    MYSQL_CLIENT_FLAGS = "2048"
    # PHP tuning
    PHP_MEMORY_LIMIT = "512M"
    PHP_UPLOAD_LIMIT = "1024M"
  }

  identity {
    type = "SystemAssigned"
  }

  tags = var.tags

  depends_on = [
    azurerm_mysql_flexible_database.db,
    azurerm_mysql_flexible_server_firewall_rule.allow_azure
  ]
}