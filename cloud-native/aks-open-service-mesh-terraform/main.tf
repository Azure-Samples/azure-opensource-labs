terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">=3.32.0"
    }

    azapi = {
      source  = "Azure/azapi"
      version = ">=1.1.0"
    }

    random = {
      source  = "hashicorp/random"
      version = ">=3.4.3"
    }
  }
}


provider "azurerm" {
  features {
    resource_group {
      prevent_deletion_if_contains_resources = false
    }
  }
}

data "azurerm_client_config" "current" {}

resource "random_pet" "osm" {
  separator = ""
  length    = 2
}

resource "azurerm_resource_group" "osm" {
  name     = "rg-${random_pet.osm.id}"
  location = var.location
  tags     = var.tags
}

resource "azurerm_log_analytics_workspace" "osm" {
  name                = "law-${random_pet.osm.id}"
  resource_group_name = azurerm_resource_group.osm.name
  location            = azurerm_resource_group.osm.location
  sku                 = "PerGB2018"
  retention_in_days   = 30
}

resource "azurerm_key_vault" "osm" {
  name                        = "akv-${random_pet.osm.id}"
  location                    = azurerm_resource_group.osm.location
  resource_group_name         = azurerm_resource_group.osm.name
  enabled_for_disk_encryption = true
  tenant_id                   = data.azurerm_client_config.current.tenant_id
  soft_delete_retention_days  = 7
  purge_protection_enabled    = false

  sku_name = "standard"

  access_policy {
    tenant_id = data.azurerm_client_config.current.tenant_id
    object_id = data.azurerm_client_config.current.object_id

    certificate_permissions = [
      "Backup",
      "Create",
      "Delete",
      "DeleteIssuers",
      "Get",
      "GetIssuers",
      "Import",
      "List",
      "ListIssuers",
      "ManageContacts",
      "ManageIssuers",
      "Purge",
      "Recover",
      "Restore",
      "SetIssuers",
      "Update"
    ]

    key_permissions = [
      "Backup",
      "Create",
      "Decrypt",
      "Delete",
      "Encrypt",
      "Get",
      "Import",
      "List",
      "Purge",
      "Recover",
      "Restore",
      "Sign",
      "UnwrapKey",
      "Update",
      "Verify",
      "WrapKey",
      "Release",
      "Rotate",
      "GetRotationPolicy",
      "SetRotationPolicy"
    ]

    secret_permissions = [
      "Backup",
      "Delete",
      "Get",
      "List",
      "Purge",
      "Recover",
      "Restore",
      "Set"
    ]

    storage_permissions = [
      "Backup",
      "Delete",
      "DeleteSAS",
      "Get",
      "GetSAS",
      "List",
      "ListSAS",
      "Purge",
      "Recover",
      "RegenerateKey",
      "Restore",
      "Set",
      "SetSAS",
      "Update"
    ]
  }
}

resource "azurerm_dns_zone" "osm" {
  name                = "sample.com"
  resource_group_name = azurerm_resource_group.osm.name
}

resource "azurerm_kubernetes_cluster" "osm" {
  name                = "aks-${random_pet.osm.id}"
  resource_group_name = azurerm_resource_group.osm.name
  location            = azurerm_resource_group.osm.location
  dns_prefix          = "aks-${random_pet.osm.id}"

  default_node_pool {
    name       = "default"
    node_count = 3
    vm_size    = "Standard_D4s_v5"
  }

  oms_agent {
    log_analytics_workspace_id = azurerm_log_analytics_workspace.osm.id
  }

  key_vault_secrets_provider {
    secret_rotation_enabled  = true
    secret_rotation_interval = "2m"
  }

  web_app_routing {
    dns_zone_id = azurerm_dns_zone.osm.id
  }

  open_service_mesh_enabled = true

  identity {
    type = "SystemAssigned"
  }
}