param location string = resourceGroup().location
param userPrincipalId string = ''

var managedIdentityName = '${resourceGroup().name}-identity'

var roleAssignmentName = guid(subscription().id, resourceGroup().id, 'Azure Kubernetes Service RBAC Cluster Admin', userPrincipalId)

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

resource roleAssignment 'Microsoft.Authorization/roleAssignments@2020-04-01-preview' = if (!empty(userPrincipalId)) {
  name: roleAssignmentName
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', 'b1ff04bb-8a4e-4dc4-8eb5-8693973ce19b') // Azure Kubernetes Service RBAC Cluster Admin role
    principalId: userPrincipalId
    principalType: 'User'
    scope: resourceGroup().id
  }
}
