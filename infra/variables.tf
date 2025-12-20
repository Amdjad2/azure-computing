variable "project_name" {
  description = "Nom du projet"
  type        = string
}

variable "environment" {
  description = "Environnement (dev, prod)"
  type        = string
}

variable "location" {
  description = "Région Azure"
  type        = string
  default     = "francecentral"
}

app_settings = {
  STORAGE_ACCOUNT_NAME = azurerm_storage_account.storage.name
  TABLE_NAME           = azurerm_storage_table.messages.name
}
