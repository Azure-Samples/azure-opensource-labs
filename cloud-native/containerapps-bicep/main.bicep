targetScope = 'subscription'

param resourceGroup string = 'my-container-apps'
param location string = deployment().location

resource rg 'Microsoft.Resources/resourceGroups@2021-04-01' = {
  name: resourceGroup
  location: location
}

module containerapp './containerapp.bicep' = {
  name: '${resourceGroup}-containerapp'
  scope: rg
  params: {
    location: location
  }
}

module postgresKeyvault './postgres-keyvault.bicep' = {
  name: '${resourceGroup}-postgres-keyvault'
  scope: rg
  params: {
    location: location
  }
}
