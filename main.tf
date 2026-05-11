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
resource "random_integer" "ri" {
  min = 100
  max = 999
}

# ============================================================
# RESOURCE GROUP
# ============================================================
resource "azurerm_resource_group" "rg" {
  name     = "${var.resource_group_name}-${random_integer.ri.result}"
  location = var.location
}

# ============================================================
# APP SERVICE PLAN
# ============================================================
resource "azurerm_service_plan" "plan" {
  name                = "${var.app_service_plan_name}-${random_integer.ri.result}"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location

  os_type  = "Linux"
  sku_name = "B2"
}

# ============================================================
# MYSQL FLEXIBLE SERVER
# ============================================================
resource "azurerm_mysql_flexible_server" "mysql" {
  name                = "mysql-nextcloud-${random_integer.ri.result}"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location

  administrator_login    = var.mysql_admin_user
  administrator_password = var.mysql_admin_password

  sku_name = "B_Standard_B1ms"

  version = "8.0.21"

  backup_retention_days = 7

  storage {
    size_gb = 20
  }

  tags = var.tags
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
  name                = "AllowAzureServices"
  resource_group_name = azurerm_resource_group.rg.name
  server_name         = azurerm_mysql_flexible_server.mysql.name

  start_ip_address = "0.0.0.0"
  end_ip_address   = "0.0.0.0"
}

# ============================================================
# LINUX WEB APP (NEXTCLOUD)
# ============================================================
resource "azurerm_linux_web_app" "nextcloud" {
  name                = "nextcloud-${random_integer.ri.result}"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location

  service_plan_id = azurerm_service_plan.plan.id

  https_only = true

  site_config {
    always_on = true

    health_check_path = "/status.php"

    app_command_line = "/entrypoint.sh apache2-foreground"

    application_stack {
      docker_image_name = "nextcloud:30-apache"
    }
  }

  app_settings = {
    #WEBSITES_ENABLE_APP_SERVICE_STORAGE = "true"
    WEBSITES_PORT                       = "80"

    # IMPORTANT
    WEBSITES_CONTAINER_START_TIME_LIMIT = "1800"

    #NEXTCLOUD_DATA_DIR = "/home/site/wwwroot/data"

    NEXTCLOUD_TRUSTED_DOMAINS = "nextcloud-${random_integer.ri.result}.azurewebsites.net"

    NEXTCLOUD_ADMIN_USER     = var.nextcloud_admin_user
    NEXTCLOUD_ADMIN_PASSWORD = var.nextcloud_admin_password

    MYSQL_HOST     = azurerm_mysql_flexible_server.mysql.fqdn
    MYSQL_DATABASE = azurerm_mysql_flexible_database.db.name

    # IMPORTANT
    MYSQL_USER     = var.mysql_admin_user
    MYSQL_PASSWORD = var.mysql_admin_password

    # SSL
    MYSQL_CLIENT_FLAGS = "MYSQLI_CLIENT_SSL"

    PHP_MEMORY_LIMIT = "512M"
    PHP_UPLOAD_LIMIT = "1024M"
  }

  tags = var.tags
}