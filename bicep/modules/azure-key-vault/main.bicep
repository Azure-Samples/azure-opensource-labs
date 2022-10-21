param name string
param location string
param tags object

@allowed([
  'premium'
  'standard'
])
param sku string = 'standard'

@description('The object ID of a user, service principal or security group in AAD tenant.')
param userObjectId string
param tenantId string

@description('List of AccessPolicyEntry which is used when granting additional permissions for other users or managed identities')
param accessPolicies array = []

resource vault 'Microsoft.KeyVault/vaults@2022-07-01' = {
  name: name
  location: location
  tags: tags
  properties: {
    accessPolicies: [
      {
        objectId: userObjectId
        permissions: {
          certificates: [
            'all'
          ]
          keys: [
            'all'
          ]
          secrets: [
            'all'
          ]
          storage: [
            'all'
          ]
        }
        tenantId: tenantId
      }
    ]
    sku: {
      family: 'A'
      name: sku
    }
    tenantId: tenantId
  }
}

resource resourceAccessPolicies 'Microsoft.KeyVault/vaults/accessPolicies@2022-07-01' = if (!empty(accessPolicies)) {
  name: 'add'
  parent: vault
  properties: {
    accessPolicies: accessPolicies
  }
}
