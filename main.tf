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

# Генериране на случаен суфикс за уникалност на ресурсите
resource "random_integer" "ri" {
  min = 10
  max = 99
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
# SQL Server (проверено, че работи с твоя акаунт)
# ============================================
resource "azurerm_mssql_server" "sqlserver" {
  name                         = "${var.sql_server_name}-${random_integer.ri.result}"
  resource_group_name          = azurerm_resource_group.arg.name
  location                     = azurerm_resource_group.arg.location
  version                      = "12.0"
  administrator_login          = var.sql_admin_name
  administrator_login_password = var.sql_admin_password
}

resource "azurerm_mssql_database" "database" {
  name                 = var.sql_database_name
  server_id            = azurerm_mssql_server.sqlserver.id
  collation            = "SQL_Latin1_General_CP1_CI_AS"
  license_type         = "LicenseIncluded"
  max_size_gb          = 2
  sku_name             = "S0"
  zone_redundant       = false
  storage_account_type = "Local"
}

resource "azurerm_mssql_firewall_rule" "firewallrule" {
  name             = var.firewall_rule_name
  server_id        = azurerm_mssql_server.sqlserver.id
  start_ip_address = "0.0.0.0"
  end_ip_address   = "0.0.0.0"
}

# Linux Web App (.NET 6)
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

  # Connection string за MySQL
  connection_string {
    name  = "DefaultConnection"
    type  = "SQLAzure"
    value = "Data Source=tcp:${azurerm_mssql_server.sqlserver.fully_qualified_domain_name},1433;Initial Catalog=${azurerm_mssql_database.database.name};User ID=${azurerm_mssql_server.sqlserver.administrator_login};Password=${var.sql_admin_password};Trusted_Connection=False;MultipleActiveResultSets=True;Encrypt=True;"
  }

  app_settings = {
    "WEBSITE_RUN_FROM_PACKAGE" = "0"
  }

  tags = var.tags
}