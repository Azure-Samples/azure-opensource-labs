param location string
param clusterId string
param dnsZoneResourceId string = ''

var clusterName = split(clusterId, '/')[8]
var attachDnsZone = dnsZoneResourceId != ''

resource updateManagedCluster 'Microsoft.ContainerService/managedClusters@2022-08-03-preview' = {
  name: clusterName
  location: location
  properties: {
    mode: 'Incremental'
    id: clusterId
    ingressProfile: {
      webAppRouting: {
        dnsZoneResourceId: attachDnsZone ? dnsZoneResourceId : null
        enabled: true
      }
    }
  }
}
