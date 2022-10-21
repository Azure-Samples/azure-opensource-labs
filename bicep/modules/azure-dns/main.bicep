param name string
param location string
param tags object

@allowed([
  'Public'
  'Private'
])
param zoneType string

resource dnsZone 'Microsoft.Network/dnsZones@2018-05-01' = {
  name: name
  location: location
  tags: tags
  properties: {
    zoneType: zoneType
  }
}

output id string = dnsZone.id
