param name string
param location string
param tags object
param vnetAddressPrefix string
param snetAddressPrefix string
param snetName string
param networkSecurityGroupId string
param dnsServer string

resource virtualNetwork 'Microsoft.Network/virtualNetworks@2022-01-01' = {
  name: name
  location: location
  tags: tags
  properties: {
    addressSpace: {
      addressPrefixes: [
        vnetAddressPrefix
      ]
    }
    dhcpOptions: (!empty(dnsServer) ? {
      dnsServers: [
        dnsServer
      ]
    } : null)
    subnets: [
      {
        name: snetName
        properties: {
          addressPrefix: snetAddressPrefix
          networkSecurityGroup: {
            id: networkSecurityGroupId
          }
        }
      }
    ]
  }
}

output id string = virtualNetwork.id
output name string = virtualNetwork.name
output subnetId string = virtualNetwork.properties.subnets[0].id
