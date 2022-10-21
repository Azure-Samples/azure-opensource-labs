param dnsZoneName string
param principalId string

resource dnsZone 'Microsoft.Network/dnsZones@2018-05-01' existing = {
  name: dnsZoneName
}

// Get the role definition resource by name, to find the name for the role DNS Zone Contributor, you can look 
// it up at the following url: https://learn.microsoft.com/en-us/azure/role-based-access-control/built-in-roles#dns-zone-contributor
resource dnsZoneContributorRoleDefinition 'Microsoft.Authorization/roleDefinitions@2022-04-01' existing = {
  scope: subscription()
  name: 'befefa01-2a29-4197-83a8-272ff33ce314'
}

resource dnsZoneContributorRoleAssignment 'Microsoft.Authorization/roleAssignments@2020-08-01-preview' = {
  name: guid(dnsZone.id, 'DNS Zone Contributor')
  scope: dnsZone
  properties: {
    roleDefinitionId: dnsZoneContributorRoleDefinition.id
    principalId: principalId
    principalType: 'User'
  }
}
