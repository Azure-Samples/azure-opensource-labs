param clusterName string = 'aks1'
param namespace string = 'default'

resource aksCluster 'Microsoft.ContainerService/managedClusters@2022-05-02-preview' existing = {
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
