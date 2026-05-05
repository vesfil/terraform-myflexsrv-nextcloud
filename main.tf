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
  features {}
  subscription_id = "45ab7c0b-0483-4cfa-b5bb-498a103b8661"
}

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

# Linux Web App с PHP за Nextcloud (използва SQLite)
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
    "WEBSITE_RUN_FROM_PACKAGE"            = "0"
    "WEBSITES_ENABLE_APP_SERVICE_STORAGE" = "true"
    "NEXTCLOUD_DATA_DIR"                  = "/home/site/wwwroot/data"
  }

  tags = var.tags
}