param managedClusterName string
param userNodes array

// Get the managed cluster by name
resource managedCluster 'Microsoft.ContainerService/managedClusters@2022-08-03-preview' existing = {
  name: managedClusterName
}

resource userNodePools 'Microsoft.ContainerService/managedClusters/agentPools@2022-07-02-preview' = [for i in range(0, length(userNodes)): {
  name: userNodes[i].name
  parent: managedCluster
  properties: {
    vmSize: userNodes[i].vmSize
    mode: userNodes[i].mode
    enableAutoScaling: userNodes[i].enableAutoScaling
    count: contains(userNodes[i], 'maxCount') ? userNodes[i].maxCount : 1
    minCount: userNodes[i].enableAutoScaling && contains(userNodes[i], 'minCount') ? userNodes[i].minCount : null
    maxCount: userNodes[i].enableAutoScaling && contains(userNodes[i], 'maxCount') ? userNodes[i].maxCount : null
    scaleDownMode: userNodes[i].enableAutoScaling && contains(userNodes[i], 'scaleDownMode') ? userNodes[i].scaleDownMode : null
    nodeTaints: empty(userNodes[i].nodeTaints) ? null : userNodes[i].nodeTaints
    type: userNodes[i].type
    osDiskType: userNodes[i].osDiskType
    vnetSubnetID: empty(userNodes[i].vnetSubnetID) ? null : userNodes[i].vnetSubnetID
  }
}]
