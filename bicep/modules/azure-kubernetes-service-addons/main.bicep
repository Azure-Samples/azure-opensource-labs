param location string
param clusterId string

@description('AKS addons to enable')
param addonProfiles object

@description('Pull out the cluster name from the resource ID')
var clusterName = split(clusterId, '/')[8]

resource managedCluster 'Microsoft.ContainerService/managedClusters@2022-08-03-preview' = {
  name: clusterName
  location: location
  properties: {
    mode: 'Incremental'
    id: clusterId
    addonProfiles: addonProfiles
  }
}
