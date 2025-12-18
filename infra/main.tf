locals {
  prefix = "${var.project_name}-${var.environment}"
}

resource "azurerm_resource_group" "rg" {
  name     = "${local.prefix}-rg"
  location = var.location
}

resource "azurerm_service_plan" "app_plan" {
  name                = "${local.prefix}-plan"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  os_type  = "Linux"
  sku_name = "B1"
}

resource "azurerm_linux_web_app" "webapp" {
  name                = "${local.prefix}-app"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  service_plan_id     = azurerm_service_plan.app_plan.id

  identity {
    type = "SystemAssigned"
  }

  site_config {
    always_on = true
  }
}

	### Création account storage 
resource "azurerm_storage_account" "storage" {
  name                     = replace("${var.project_name}${var.environment}", "-", "")
  resource_group_name      = azurerm_resource_group.rg.name
  location                 = azurerm_resource_group.rg.location
  account_tier             = "Standard"
  account_replication_type = "LRS"

  allow_nested_items_to_be_public = false
}

resource "azurerm_storage_table" "messages" {
  name                 = "messages"
  storage_account_name = azurerm_storage_account.storage.name
}

	### Accès RBAC
resource "azurerm_role_assignment" "storage_access" {
  scope                = azurerm_storage_account.storage.id
  role_definition_name = "Storage Table Data Contributor"
  principal_id         = azurerm_linux_web_app.webapp.identity[0].principal_id
}
