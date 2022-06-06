targetScope = 'subscription'

param resourceGroup string = '220600-keda'
param location string = deployment().location
param deployScript bool = false
param scriptUri string = 'https://raw.githubusercontent.com/Azure-Samples/azure-opensource-labs/main/cloud-native/aks-bicep-keda/01-aks/deploy-script-keda.sh'

resource rg 'Microsoft.Resources/resourceGroups@2021-04-01' = {
  name: resourceGroup
  location: location
}

module aks './aks.bicep' = {
  name: '${resourceGroup}-aks'
  scope: rg
  params: {
    location: location
  }
}

module script './deploy-script.bicep' = if(deployScript) {
  name: '${resourceGroup}-deployscript'
  scope: rg
  params: {
    location: location
    scriptUri: scriptUri
  }
  dependsOn: [
    aks
  ]
}
