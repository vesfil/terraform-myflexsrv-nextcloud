terraform {
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
  features {
  }
  subscription_id = "45ab7c0b-0483-4cfa-b5bb-498a103b8661"
}

resource "random_integer" "ri" {
  min = 10000
  max = 99999
}

resource "terraform_data" "trigger" {
  input = timestamp()
}

# Resource Group
resource "azurerm_resource_group" "arg" {
  name     = "${var.resource_group_name}-${random_integer.ri.result}"
  location = var.location
}

# App Service Plan (Linux, F1 - безплатен)
resource "azurerm_service_plan" "asp" {
  name                = "${var.app_service_plan_name}-${random_integer.ri.result}"
  resource_group_name = azurerm_resource_group.arg.name
  location            = azurerm_resource_group.arg.location
  os_type             = "Linux"
  sku_name            = "F1"
}

# ============================================
# MySQL Single Server (Basic план - поддържан от учебния акаунт)
# ============================================
resource "azurerm_mysql_server" "mysql" {
  name                = "${var.mysql_server_name}-${random_integer.ri.result}"
  resource_group_name = azurerm_resource_group.arg.name
  location            = azurerm_resource_group.arg.location

  sku_name = "B_Gen5_1"   # Basic план, 1 vCore, поддържан от учебния акаунт

  storage_mb = 5120  # 5 GB - минимално

  administrator_login          = var.mysql_admin_username
  administrator_login_password = var.mysql_admin_password

  version                = "8.0"
  ssl_enforcement_enabled = false   # За тестови цели (за production включи SSL в connection string)

  tags = var.tags
}

# MySQL Database
resource "azurerm_mysql_database" "mysql_db" {
  name                = var.mysql_database_name
  resource_group_name = azurerm_resource_group.arg.name
  server_name         = azurerm_mysql_server.mysql.name
  charset             = "utf8mb4"
  collation           = "utf8mb4_unicode_ci"
}

# Firewall Rule - позволява на Azure услуги (вкл. App Service) да се свързват
resource "azurerm_mysql_firewall_rule" "allow_azure_services" {
  name                = "AllowAllAzureServices"
  resource_group_name = azurerm_resource_group.arg.name
  server_name         = azurerm_mysql_server.mysql.name
  start_ip_address    = "0.0.0.0"
  end_ip_address      = "0.0.0.0"
}

# Linux Web App (PHP за Nextcloud)
resource "azurerm_linux_web_app" "alwa" {
  name                = "${var.app_service_plan_name}-${random_integer.ri.result}"
  resource_group_name = azurerm_resource_group.arg.name
  location            = azurerm_resource_group.arg.location
  service_plan_id     = azurerm_service_plan.asp.id

  site_config {
    application_stack {
      php_version = "8.2"
    }
    always_on = false
  }

  app_settings = {
    "WEBSITE_RUN_FROM_PACKAGE" = "0"
  }

  connection_string {
    name  = "DefaultConnection"
    type  = "MySQL"
    value = "Database=${azurerm_mysql_database.mysql_db.name};Data Source=${azurerm_mysql_server.mysql.fqdn};User Id=${var.mysql_admin_username}@${azurerm_mysql_server.mysql.name};Password=${var.mysql_admin_password}"
  }

  tags = var.tags
}