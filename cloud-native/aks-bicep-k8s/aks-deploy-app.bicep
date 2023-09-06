param clusterName string = 'aks1'
param namespace string = 'default'

resource aksCluster 'Microsoft.ContainerService/managedClusters@2023-05-01' existing = {
  name: clusterName
}

module app './azure-vote.bicep' = {
  name: '${resourceGroup().name}-app'
  params: {
    kubeConfig: aksCluster.listClusterAdminCredential().kubeconfigs[0].value
    namespace: namespace
  }
}

output appOutputs object = app.outputs
