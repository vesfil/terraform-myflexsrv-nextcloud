# ============================================================
# TERRAFORM
# ============================================================
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

# ============================================================
# PROVIDER
# ============================================================
provider "azurerm" {
  features {}
  subscription_id = var.subscription_id
}

# ============================================================
# RANDOM SUFFIX
# ============================================================
resource "random_integer" "suffix" {
  min = 1000
  max = 9999
}

# ============================================================
# RESOURCE GROUP
# ============================================================
resource "azurerm_resource_group" "rg" {
  name     = "${var.resource_group_name}-${random_integer.suffix.result}"
  location = var.location
}

# ============================================================
# APP SERVICE PLAN
# ============================================================
resource "azurerm_service_plan" "plan" {
  name                = "${var.app_service_plan_name}-${random_integer.suffix.result}"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location

  os_type  = "Linux"
  sku_name = "B2"
}

# ============================================================
# MYSQL FLEXIBLE SERVER (SECURE - DO NOT DISABLE SSL)
# ============================================================
resource "azurerm_mysql_flexible_server" "mysql" {
  name                = "nc-mysql-${random_integer.suffix.result}"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location

  administrator_login    = var.mysql_admin_user
  administrator_password = var.mysql_admin_password

  sku_name = "B_Standard_B2s"
  version  = "8.0.21"

  storage {
    size_gb = 32
  }

  #backup_retention_days = 7

  tags = var.tags
}

# ============================================================
# FORCE TLS REQUIREMENT (KEEP ON)
# ============================================================
resource "azurerm_mysql_flexible_server_configuration" "require_secure_transport" {
  name                = "require_secure_transport"
  resource_group_name = azurerm_resource_group.rg.name
  server_name         = azurerm_mysql_flexible_server.mysql.name
  value               = "ON"
}

# ============================================================
# NEXTCLOUD WEB APP
# ============================================================
resource "azurerm_linux_web_app" "nextcloud" {
  name                = "nextcloud-${random_integer.suffix.result}"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location

  service_plan_id = azurerm_service_plan.plan.id

  https_only = true

  site_config {
    always_on = true

    application_stack {
      docker_image_name = "nextcloud:30-apache"
    }

    # FIX REQUIRED BY AZURE PROVIDER
    health_check_path = "/status.php"
    health_check_eviction_time_in_min = 10
  }

  app_settings = {

    # ========================================================
    # CORE
    # ========================================================
    WEBSITES_ENABLE_APP_SERVICE_STORAGE = "true"
    WEBSITES_PORT                       = "80"
    WEBSITES_CONTAINER_START_TIME_LIMIT = "1800"

    # ========================================================
    # NEXTCLOUD AUTH
    # ========================================================
    NEXTCLOUD_ADMIN_USER     = var.nextcloud_admin_user
    NEXTCLOUD_ADMIN_PASSWORD = var.nextcloud_admin_password
    NEXTCLOUD_TRUSTED_DOMAINS = "nextcloud-${random_integer.suffix.result}.azurewebsites.net"

    # ========================================================
    # DATABASE
    # ========================================================
    MYSQL_HOST     = azurerm_mysql_flexible_server.mysql.fqdn
    MYSQL_DATABASE = azurerm_mysql_flexible_database.db.name
    MYSQL_USER     = var.mysql_admin_user
    MYSQL_PASSWORD = var.mysql_admin_password

    # ========================================================
    # 🔥 CRITICAL SSL FIX FOR PDO (THIS IS THE REAL FIX)
    # ========================================================
    MYSQL_SSL_MODE = "REQUIRED"

    # Force PHP CA bundle for TLS validation
    SSL_CERT_FILE = "/etc/ssl/certs/ca-certificates.crt"

    # IMPORTANT: forces PDO SSL capability in many builds
    MYSQL_CLIENT_FLAGS = "2048"

    # ========================================================
    # PERFORMANCE
    # ========================================================
    PHP_MEMORY_LIMIT = "512M"
    PHP_UPLOAD_LIMIT = "1024M"
  }

  tags = var.tags
}