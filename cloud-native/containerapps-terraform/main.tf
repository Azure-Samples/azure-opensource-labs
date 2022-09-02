terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">=3.0.0"
    }

    azapi = {
      source  = "azure/azapi"
      version = ">=0.5.0"
    }
  }
}

provider "azurerm" {
  features {
    resource_group {
      prevent_deletion_if_contains_resources = false
    }

    key_vault {
      purge_soft_delete_on_destroy = false
    }
  }
}

resource "random_pet" "aca" {
  length    = 2
  separator = ""
}

resource "random_integer" "aca" {
  min = 000
  max = 999
}

locals {
  resource_name        = format("%s", random_pet.aca.id)
  resource_name_unique = format("%s%s", random_pet.aca.id, random_integer.aca.result)
  location             = "eastus"
}

resource "azurerm_resource_group" "aca" {
  name     = "rg-${local.resource_name}"
  location = local.location

  tags = {
    repo = "git@github.com:Azure-Samples/azure-opensource-labs.git"
  }
}

resource "azurerm_virtual_network" "aca" {
  count               = var.environment_virtual_network.use_custom_vnet ? 1 : 0
  name                = "vnet-${local.resource_name}"
  address_space       = ["10.0.0.0/16"]
  resource_group_name = azurerm_resource_group.aca.name
  location            = azurerm_resource_group.aca.location

  subnet {
    name           = "snet-environment"
    address_prefix = "10.0.0.0/23"
  }

  subnet {
    name           = "snet-sandbox"
    address_prefix = "10.0.2.0/23"
  }
}

resource "azurerm_container_registry" "aca" {
  name                = "aca${local.resource_name_unique}"
  resource_group_name = azurerm_resource_group.aca.name
  location            = azurerm_resource_group.aca.location
  sku                 = "Basic"
  admin_enabled       = true
}

resource "azurerm_log_analytics_workspace" "aca" {
  name                = "law-${local.resource_name_unique}"
  resource_group_name = azurerm_resource_group.aca.name
  location            = azurerm_resource_group.aca.location
  sku                 = "PerGB2018"
  retention_in_days   = 30
}

# https://registry.terraform.io/providers/Azure/azapi/latest/docs
# https://docs.microsoft.com/en-us/azure/templates/microsoft.app/2022-03-01/managedenvironments?tabs=bicep&pivots=deployment-language-terraform
resource "azapi_resource" "env" {
  type      = "Microsoft.App/managedEnvironments@2022-03-01"
  name      = "env-${local.resource_name}"
  parent_id = azurerm_resource_group.aca.id
  location  = azurerm_resource_group.aca.location

  body = jsonencode({
    properties = {
      appLogsConfiguration = {
        destination = "log-analytics"
        logAnalyticsConfiguration = {
          customerId = azurerm_log_analytics_workspace.aca.workspace_id
          sharedKey  = azurerm_log_analytics_workspace.aca.primary_shared_key
        }
      }
      # if you want to use a custom VNET, set the vnetConfiguration property
      vnetConfiguration = var.environment_virtual_network.use_custom_vnet ? {
        infrastructureSubnetId = element(azurerm_virtual_network.aca[0].subnet.*.id, index(azurerm_virtual_network.aca[0].subnet.*.name, "snet-environment"))
        internal               = var.environment_virtual_network.is_internal
      } : null
    }
  })
}

# https://docs.microsoft.com/en-us/azure/templates/microsoft.app/2022-03-01/containerapps?tabs=bicep&pivots=deployment-language-terraform
resource "azapi_resource" "helloworld" {
  type      = "Microsoft.App/containerApps@2022-03-01"
  name      = "helloworld"
  parent_id = azurerm_resource_group.aca.id
  location  = azurerm_resource_group.aca.location

  body = jsonencode({
    properties = {
      managedEnvironmentId = azapi_resource.env.id
      configuration = {
        ingress = {
          allowInsecure = false
          external      = true
          targetPort    = 80
          traffic = [
            {
              label          = "dev"
              latestRevision = true
              weight         = 100
            }
          ]
        }
      }
      template = {
        containers = [
          {
            name  = "helloworld"
            image = "mcr.microsoft.com/azuredocs/containerapps-helloworld:latest"
            resources = {
              cpu    = 0.5
              memory = "1.0Gi"
            }
          }
        ]
        scale = {
          minReplicas = 0
          maxReplicas = 30
        }
      }
    }
  })

  # this tells azapi to pull out properties and stuff into the output attribute for the object
  response_export_values = ["properties.configuration.ingress.fqdn"]
}

# https://docs.microsoft.com/en-us/azure/templates/microsoft.dashboard/grafana?pivots=deployment-language-terraform
resource "azapi_resource" "amg" {
  type      = "Microsoft.Dashboard/grafana@2022-08-01"
  name      = "amg-${local.resource_name}"
  parent_id = azurerm_resource_group.aca.id
  location  = azurerm_resource_group.aca.location

  identity {
    type = "SystemAssigned"
  }

  body = jsonencode({
    properties = {
      apiKey                            = "Enabled"
      autoGeneratedDomainNameLabelScope = "TenantReuse"
      deterministicOutboundIP           = "Enabled"
      publicNetworkAccess               = "Enabled"
      zoneRedundancy                    = "Disabled"
    }
    sku = {
      name = "Standard"
    }
  })

  # this tells azapi to pull out properties and stuff into the output attribute for the object
  response_export_values = ["identity.principalId"]
}

data "azurerm_subscription" "aca" {}

data "azurerm_client_config" "aca" {}

resource "azurerm_role_assignment" "amg_reader" {
  scope                = data.azurerm_subscription.aca.id
  role_definition_name = "Monitoring Reader"
  principal_id         = jsondecode(azapi_resource.amg.output).identity.principalId
}

resource "azurerm_role_assignment" "amg_admin" {
  scope                = azapi_resource.amg.id
  role_definition_name = "Grafana Admin"
  principal_id         = data.azurerm_client_config.aca.object_id
}


# // todo: https://registry.terraform.io/providers/hashicorp/azuread/latest/docs/resources/service_principal