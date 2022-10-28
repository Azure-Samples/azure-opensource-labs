param name string
param location string
param tags object

@allowed([
  'Basic'
  'Standard'
  'Premium'
])
@description('Defaults to Standard')
param sku string = 'Standard'

@allowed([
  'SystemAssigned'
  'UserAssigned'
])
@description('Two options are available: SystemAssigned or UserAssigned')
param managedIdentityType string = 'SystemAssigned'

@description('Required when managed identity type is set to UserAssigned')
param userAssignedIdentities object = {}

param adminUserEnabled bool = false

param anonymousPullEnabled bool = false

@description('Disableing public network access is not supported for Basic and Standard SKUs')
param publicNetworkAccess bool = (sku == 'Premium' ? false : true)

resource registry 'Microsoft.ContainerRegistry/registries@2022-02-01-preview' = {
  name: name
  location: location
  tags: tags
  sku: {
    name: sku
  }
  identity: {
    type: managedIdentityType
    userAssignedIdentities: managedIdentityType != 'SystemAssigned' ? userAssignedIdentities : null
  }
  properties: {
    adminUserEnabled: adminUserEnabled
    anonymousPullEnabled: anonymousPullEnabled
    publicNetworkAccess: publicNetworkAccess ? 'Enabled' : 'Disabled'
  }
}

output name string = registry.name
