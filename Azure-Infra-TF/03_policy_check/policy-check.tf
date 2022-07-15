#functionapp

provider "curl" {
}

locals {
  region                        = "westeurope"
  resource_group_name           = "pythonazfunc"
  storage_account_name          = "pythonazfuncvhsa"
  app_service_plan_name         = "pythonazfuncvh"
  function_app_name             = "policycheckapp-vh"
  function_name                 = "policy-check"

  # Common tags to be assigned to all resources
  common_tags = {
    terraform   = "true"
    deployed_by = "Terraform_SP"
  }
}

resource "random_string" "resource_code" {
  length   = 7
  upper    = false
  numeric  = true
  lower    = true
  special  = false
}

# Create a resource group for all subsequent resources
resource "azurerm_resource_group" "this" {
  name     = local.resource_group_name
  location = local.region

  tags     = local.common_tags
}

# Create an Azure storage account to host the function releases, function executions and triggers
resource "azurerm_storage_account" "function_store" {
  name                     = "${local.storage_account_name}${random_string.resource_code.result}"
  resource_group_name      = azurerm_resource_group.this.name
  location                 = azurerm_resource_group.this.location
  account_tier             = "Standard"
  account_replication_type = "LRS"

  tags                     = local.common_tags
}

# Create a storage container for our function releases
resource "azurerm_storage_container" "function_releases" {
  name                 = "function-releases"
  storage_account_name = azurerm_storage_account.function_store.name
}

# Upload the function as packaged zip file to our storage container.
resource "azurerm_storage_blob" "function_blob" {
  name                   = "${filesha256("./policycheckapp-vh.zip")}.zip"
  source                 = "./policycheckapp-vh.zip"
  storage_account_name   = azurerm_storage_account.function_store.name
  storage_container_name = azurerm_storage_container.function_releases.name
  type                   = "Block"
}

# Create an App Service plan for our function
resource "azurerm_service_plan" "this" {
  name                = local.app_service_plan_name
  resource_group_name = azurerm_resource_group.this.name
  location            = azurerm_resource_group.this.location
  os_type             = "Linux"
  sku_name            = "Y1"

  tags                = local.common_tags
}

# Create the function app
resource "azurerm_linux_function_app" "this" {
  name                = local.function_app_name
  resource_group_name = azurerm_resource_group.this.name
  location            = azurerm_resource_group.this.location

  enabled             = true
  service_plan_id     = azurerm_service_plan.this.id

  storage_account_name          = azurerm_storage_account.function_store.name
  storage_uses_managed_identity = true

  identity {
    type = "SystemAssigned"
  }

  site_config {
    application_stack {
      python_version = "3.9"
    }
  }
  app_settings = {
    "WEBSITE_RUN_FROM_PACKAGE" = "https://${azurerm_storage_account.function_store.name}.blob.core.windows.net/function-releases/${azurerm_storage_blob.function_blob.name}"
  }

  tags               = local.common_tags
}

# Allow our function's managed identity to have r/w access to the storage account
resource "azurerm_role_assignment" "function_app_to_function_releases_container_access" {
  principal_id         = azurerm_linux_function_app.this.identity[0].principal_id
  scope                = azurerm_storage_account.function_store.id
  role_definition_name = "Storage Blob Data Contributor"
}

# get current subscription accessed by the TF SP
data "azurerm_subscription" "current" {
}

# Allow our function's managed identity to have access to required policy infos in the subs
resource "azurerm_role_assignment" "function_app_to_policies_access" {
  principal_id         = azurerm_linux_function_app.this.identity[0].principal_id
  scope                = data.azurerm_subscription.current.id
  role_definition_name = "Resource Policy Contributor"
}

# read the default_host key of the functionapp to get authorization secret
data "azurerm_function_app_host_keys" "default_key" {
  name                = azurerm_linux_function_app.this.name
  resource_group_name = azurerm_resource_group.this.name
}

locals {
  function_url = "https://${local.function_app_name}.azurewebsites.net/api/${local.function_name}?code=${data.azurerm_function_app_host_keys.default_key.default_function_key}&clientId=default"
}

# collect the policy check results
data "curl" "get_noncompliants" {
  http_method = "GET"
  uri = local.function_url
}

output "noncompliant_resources" {
  value = data.curl.get_noncompliants.response
}