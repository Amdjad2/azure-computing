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
  name                  = "messages"
  storage_account_name    = azurerm_storage_account.storage.name
}

  ### Accès RBAC
resource "azurerm_role_assignment" "storage_access" {
  scope                = azurerm_storage_account.storage.id
  role_definition_name = "Storage Table Data Contributor"
  principal_id         = azurerm_linux_web_app.webapp.identity[0].principal_id

  depends_on = [
    azurerm_linux_web_app.webapp
  ]
}

  ### Accès RBAC Key Vault
resource "azurerm_role_assignment" "kv_access" {
  scope                = azurerm_key_vault.kv.id
  role_definition_name = "Key Vault Secrets User"
  principal_id         = azurerm_linux_web_app.webapp.identity[0].principal_id

  depends_on = [
    azurerm_linux_web_app.webapp
  ]
}

	### Accès RBAC
data "azurerm_client_config" "current" {}

  ### Azure Key Vault
resource "azurerm_key_vault" "kv" {
  name                        = lower(replace(substr("${local.prefix}kv", 0, 24), "_", "-"))
  location                    = azurerm_resource_group.rg.location
  resource_group_name         = azurerm_resource_group.rg.name
  tenant_id                   = data.azurerm_client_config.current.tenant_id
  sku_name                    = "standard"
  enable_rbac_authorization   = true
  purge_protection_enabled    = true
  soft_delete_retention_days  = 7
  public_network_access_enabled = true
}


	### Ajouter un secret
resource "azurerm_key_vault_secret" "storage_table_name" {
  name         = "STORAGE-TABLE-NAME"
  value        = azurerm_storage_table.messages.name
  key_vault_id = azurerm_key_vault.kv.id

  depends_on = [
    azurerm_role_assignment.kv_admin_for_terraform
  ]
}

	### Accorder un accès temporaire a mon identité
resource "azurerm_role_assignment" "kv_admin_for_terraform" {
  scope                = azurerm_key_vault.kv.id
  role_definition_name = "Key Vault Secrets Officer"
  principal_id         = data.azurerm_client_config.current.object_id
}


	### Output
output "storage_account_name" {
  value = azurerm_storage_account.storage.name
}

output "key_vault_name" {
  value = azurerm_key_vault.kv.name
}

