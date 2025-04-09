param location string = resourceGroup().location

var managedIdentityName = '${resourceGroup().name}-identity'

resource managedIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2018-11-30' = {
  name: managedIdentityName
  location: location
}

module managedCluster 'br/public:avm/res/container-service/managed-cluster:0.6.2' = {
  name: 'managedClusterDeployment'
  params: {
    // Required parameters
    name: 'aks-1'
    kubernetesVersion: '1.31.2'
    primaryAgentPoolProfiles: [
      {
        count: 1
        mode: 'System'
        name: 'system1'
        osSKU: 'AzureLinux'
        vmSize: 'Standard_D2pds_v6'
        orchestratorVersion: '1.31.2'
        availabilityZones: [1]
      }
      {
        count: 1
        mode: 'User'
        name: 'user1'
        osSKU: 'AzureLinux'
        vmSize: 'Standard_D2pds_v6'
        orchestratorVersion: '1.31.2'
        availabilityZones: [1]
      }
    ]
    // Non-required parameters
    location: location
    aadProfile: {
      aadProfileEnableAzureRBAC: true
      aadProfileManaged: true
    }
    disableLocalAccounts: true
    publicNetworkAccess: 'Enabled'
    managedIdentities: {
      userAssignedResourceIds: [
        managedIdentity.id
      ]
    }
  }
}
