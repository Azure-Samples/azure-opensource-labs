param location string = resourceGroup().location

var rand = substring(uniqueString(resourceGroup().id), 0, 6)

resource managedIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2018-11-30' = {
  name: '${resourceGroup().name}-identity'
  location: location
}

resource keyVault 'Microsoft.KeyVault/vaults@2019-09-01' = {
  name: 'keyvault${rand}'
  location: location
  properties: {
    enabledForDeployment: true
    enabledForTemplateDeployment: true
    enabledForDiskEncryption: true
    tenantId: subscription().tenantId
    sku: {
      name: 'standard'
      family: 'A'
    }
    accessPolicies: [
      {
        objectId: managedIdentity.properties.principalId
        permissions: {
          secrets: [
            'all'
          ]
        }
        tenantId: subscription().tenantId
      }
    ]
  }
}
