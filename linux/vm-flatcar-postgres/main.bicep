targetScope = 'subscription'

param resourceGroup string = 'my-postgres'
param location string = deployment().location
param firewallRuleIp string = '127.0.0.1'
param sshKey string

resource rg 'Microsoft.Resources/resourceGroups@2021-04-01' = {
  name: resourceGroup
  location: location
}

module vm './vm.bicep' = {
  name: '${resourceGroup}-vm'
  scope: rg
  params: {
    location: location
    sshKey: sshKey
    allowIpPort22: firewallRuleIp
  }
}

module postgres './postgres.bicep' = {
  name: '${resourceGroup}-postgres'
  scope: rg
  params: {
    location: location
    firewallRuleIp: firewallRuleIp
  }
}
