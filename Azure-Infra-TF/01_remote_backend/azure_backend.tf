variable "arm_client_id" {}
variable "arm_client_secret" {}
variable "arm_subscription_id" {}
variable "arm_tenant_id" {}

variable "region" {
  type        = string
  default     = "westeurope"
}

variable "ResourceGroup" {
  type        = string
  default     = "TerraformRG"
}

variable "container_name" {
  type        = string
  default     = "tfstatefile"
}

variable "company" {
  type        = string
  default     = "vhorvath2EPAM"
}


terraform {
  required_providers {
    azurerm = {
      source = "hashicorp/azurerm"
      version = "3.9.0"
    }
  }
}


provider "azurerm" {
  features {}# Configuration options
}

resource "random_string" "resource_code" {
  length   = 2
  upper    = false
  numeric  = true
  lower    = true
  special  = false
}

resource "azurerm_resource_group" "rg" {
  name     = var.ResourceGroup
  location = var.region

  tags = {
      terraform   = "true"
      deployed_by = "Terraform_SP"
  }
}

resource "azurerm_storage_account" "sa" {
  name                              = "${lower(var.company)}tfbackend${random_string.resource_code.result}"
  resource_group_name               = var.ResourceGroup
  location                          = var.region
  account_tier                      = "Standard"
  account_replication_type          = "LRS"
  cross_tenant_replication_enabled  = "false"
  min_tls_version                   = "TLS1_2"
  enable_https_traffic_only         = "true"
  queue_properties  {
     logging {
         delete                = true
         read                  = true
         write                 = true
         version               = "1.0"
         retention_policy_days = 5
     }
   }

   tags = {
      terraform   = "true"
      deployed_by = "Terraform_SP"
  }

  depends_on = [azurerm_resource_group.rg]
}

resource "azurerm_storage_container" "container" {
  name                  = var.container_name
  storage_account_name  = azurerm_storage_account.sa.name
  container_access_type = "private"
}