param location string = 'canadacentral'

resource postgres 'Microsoft.DBforPostgreSQL/flexibleServers@2021-06-01' = {
  name: '${resourceGroup().name}-identity'
  location: location
  sku: {
    name: 'Standard_D2s_v3'
    tier: 'GeneralPurpose'
  }
  properties: {
    version: '13'
  }
}
