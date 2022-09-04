data "azurerm_subscription" "aca" {}
data "azurerm_client_config" "aca" {}

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