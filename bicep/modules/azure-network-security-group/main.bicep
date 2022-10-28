param name string
param tags object
param location string

resource networkSecurityGroup 'Microsoft.Network/networkSecurityGroups@2022-01-01' = {
  name: name
  location: location
  properties: {
    securityRules: []
  }
  tags: tags
}

output id string = networkSecurityGroup.id
