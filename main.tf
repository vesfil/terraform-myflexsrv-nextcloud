terraform {
  required_version = ">= 1.5"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "4.66.0"
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

locals {
  suffix = var.environment_suffix
}

# ============================================================
# RESOURCE GROUP
# ============================================================
resource "azurerm_resource_group" "rg" {
  name     = "rg-nextcloud-${local.suffix}"
  location = var.location

  tags = var.tags
}

# ============================================================
# APP SERVICE PLAN
# ============================================================
resource "azurerm_service_plan" "plan" {
  name                = "asp-nextcloud-${local.suffix}"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location

  os_type  = "Linux"
  sku_name = "B2"

  tags = var.tags
}

# ============================================================
# MYSQL FLEXIBLE SERVER
# ============================================================
resource "azurerm_mysql_flexible_server" "mysql" {
  name                = "mysql-nextcloud-${local.suffix}"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location

  administrator_login    = var.mysql_admin_user
  administrator_password = var.mysql_admin_password

  sku_name = "B_Standard_B1ms"
  version  = "8.0.21"

  #backup_retention_days = 7

  #public_network_access_enabled = true

  storage {
    size_gb = 20
  }

  tags = var.tags
}

resource "azurerm_mysql_flexible_server_configuration" "tls" {
  name                = "require_secure_transport"
  resource_group_name = azurerm_resource_group.rg.name
  server_name         = azurerm_mysql_flexible_server.mysql.name
  value               = "OFF"
}
# ============================================================
# MYSQL DATABASE
# ============================================================
resource "azurerm_mysql_flexible_database" "db" {
  name                = var.mysql_database_name
  resource_group_name = azurerm_resource_group.rg.name
  server_name         = azurerm_mysql_flexible_server.mysql.name

  charset   = "utf8mb4"
  collation = "utf8mb4_unicode_ci"
}

# ============================================================
# FIREWALL RULE
# ============================================================
resource "azurerm_mysql_flexible_server_firewall_rule" "allow_azure" {
  name                = "AllowAzure"
  resource_group_name = azurerm_resource_group.rg.name
  server_name         = azurerm_mysql_flexible_server.mysql.name

  start_ip_address = "0.0.0.0"
  end_ip_address   = "0.0.0.0"
}

# ============================================================
# NEXTCLOUD WEB APP
# ============================================================
resource "azurerm_linux_web_app" "nextcloud" {
  name                = "nextcloud-${local.suffix}"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location

  service_plan_id = azurerm_service_plan.plan.id

  https_only = true

  site_config {
    always_on = true

    application_stack {
      docker_image_name = "nextcloud:30-apache"
    }
  }

  app_settings = {
    WEBSITES_ENABLE_APP_SERVICE_STORAGE = "false"
    WEBSITES_PORT                       = "80"
    WEBSITES_CONTAINER_START_TIME_LIMIT = "1800"

    NEXTCLOUD_ADMIN_USER     = var.nextcloud_admin_user
    NEXTCLOUD_ADMIN_PASSWORD = var.nextcloud_admin_password

    NEXTCLOUD_TRUSTED_DOMAINS = "nextcloud-${local.suffix}.azurewebsites.net"

    TRUSTED_PROXIES  = "0.0.0.0/0"
    OVERWRITEHOST    = "nextcloud-${local.suffix}.azurewebsites.net"
    OVERWRITEPROTOCOL = "https"
    OVERWRITECLIURL  = "https://nextcloud-${local.suffix}.azurewebsites.net"

    MYSQL_HOST     = azurerm_mysql_flexible_server.mysql.fqdn
    MYSQL_DATABASE = azurerm_mysql_flexible_database.db.name
    MYSQL_USER     = var.mysql_admin_user
    MYSQL_PASSWORD = var.mysql_admin_password

    PHP_MEMORY_LIMIT = "512M"
    PHP_UPLOAD_LIMIT = "1024M"
  }

  identity {
    type = "SystemAssigned"
  }

  tags = var.tags

  depends_on = [
    azurerm_mysql_flexible_database.db,
    azurerm_mysql_flexible_server_firewall_rule.allow_azure,
    azurerm_mysql_flexible_server_configuration.tls
  ]
}