targetScope = 'subscription'

param resourceGroup string = '230300-aks-bicep'
param location string = deployment().location

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

// module script './deploy-script.bicep' = if(deployScript) {
//   name: '${resourceGroup}-deployscript'
//   scope: rg
//   params: {
//     location: location
//     scriptUri: scriptUri
//   }
//   dependsOn: [
//     aks
//   ]
// }
