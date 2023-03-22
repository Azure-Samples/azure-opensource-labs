param location string = resourceGroup().location
param clusterName string = 'aks1'
param namespace string = 'default'
param deployCluster bool = true

module aks './aks.bicep' = if(deployCluster) {
  name: '${resourceGroup().name}-aks'
  params: {
    location: location
    clusterName: clusterName
  }
}

resource aksCluster 'Microsoft.ContainerService/managedClusters@2022-05-02-preview' existing = {
  name: clusterName
}

module app './azure-vote.bicep' = {
  name: '${resourceGroup().name}-app'
  params: {
    kubeConfig: aksCluster.listClusterAdminCredential().kubeconfigs[0].value
    namespace: namespace
  }
  dependsOn: [
    aks
  ]
}

output lbPublicIp string = app.outputs.frontendIp
