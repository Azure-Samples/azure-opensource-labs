param name string
param location string
param tags object

@allowed([
  'GlobalDocumentDB'
  'MongoDB'
  'Parse'
])
param kind string = 'MongoDB'

@allowed([
  '3.2'
  '3.6'
  '4.0'
  '4.2'
])
param mongoApiVersion string = '4.2'

@allowed([
  'None'
  'SystemAssigned'
  'UserAssigned'
  'SystemAssigned,UserAssigned'
])
param managedIdentityType string = 'SystemAssigned'

@description('Used when managedIdentityType is UserAssigned')
param userAssignedIdentities object = {}

@description('Array of location objects with the following properties: failoverPriority, isZoneRedundant, locationName')
param locations array

resource databaseAccount 'Microsoft.DocumentDB/databaseAccounts@2022-05-15' = {
  name: name
  location: location
  tags: tags
  kind: kind
  identity: {
    type: managedIdentityType
    userAssignedIdentities: empty(userAssignedIdentities) ? null : userAssignedIdentities
  }
  properties: {
    databaseAccountOfferType: 'Standard'
    locations: locations
    apiProperties: kind == 'MongoDB' ? {
      serverVersion: mongoApiVersion
    } : null
  }
}
