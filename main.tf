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
# MySQL Flexible Server (най-евтиният вариант B1ms)
# ============================================
resource "azurerm_mysql_flexible_server" "mysql" {
  name                = "${var.mysql_server_name}-${random_integer.ri.result}"
  resource_group_name = azurerm_resource_group.arg.name
  location            = azurerm_resource_group.arg.location

  # B1ms е най-евтиният план (~0.1449 ¥/час)
  sku_name = "GP_Standard_DS1_v2"

  administrator_login    = var.mysql_admin_username
  administrator_password = var.mysql_admin_password

  version = "8.0.21"
  zone    = "1"

  storage {
    size_gb            = 20
    auto_grow_enabled  = true
    io_scaling_enabled = true
  }

  tags = var.tags
}

# MySQL Database
resource "azurerm_mysql_flexible_database" "mysql_db" {
  name                = var.mysql_database_name
  resource_group_name = azurerm_resource_group.arg.name
  server_name         = azurerm_mysql_flexible_server.mysql.name
  charset             = "utf8mb4"
  collation           = "utf8mb4_unicode_ci"
}

# Firewall Rule - позволява на Azure услуги (вкл. App Service) да се свързват
resource "azurerm_mysql_flexible_server_firewall_rule" "allow_azure_services" {
  name                = "AllowAllAzureServices"
  resource_group_name = azurerm_resource_group.arg.name
  server_name         = azurerm_mysql_flexible_server.mysql.name
  start_ip_address    = "0.0.0.0"
  end_ip_address      = "0.0.0.0"
}

# Linux Web App (.NET 6)
resource "azurerm_linux_web_app" "alwa" {
  name                = "${var.app_service_plan_name}-${random_integer.ri.result}"
  resource_group_name = azurerm_resource_group.arg.name
  location            = azurerm_resource_group.arg.location
  service_plan_id     = azurerm_service_plan.asp.id

  site_config {
    application_stack {
      dotnet_version = "6.0"
    }
    always_on        = false
    app_command_line = "dotnet Homies.dll"
  }

  # Connection string за MySQL
  connection_string {
    name  = "DefaultConnection"
    type  = "MySQL"
    value = "Server=${azurerm_mysql_flexible_server.mysql.fqdn};Database=${azurerm_mysql_flexible_database.mysql_db.name};Uid=${var.mysql_admin_username};Pwd=${var.mysql_admin_password};SslMode=Preferred;"
  }

  tags = var.tags
}