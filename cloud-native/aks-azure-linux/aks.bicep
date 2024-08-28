param location string = resourceGroup().location
param clusterName string = 'aks1'
param nodeCount int = 1
param vmSize string = 'standard_d2s_v5'
param gpu1VmSize string = 'Standard_NC4as_T4_v3'
param gpu2VmSize string = 'Standard_NC6s_v3'
//param gpu3VmSize string = 'Standard_NC24ads_A100_v4'

param kubernetesVersion string = '1.29'

var rand = substring(uniqueString(resourceGroup().id), 0, 6)

resource managedIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2018-11-30' = {
  name: '${resourceGroup().name}-identity'
  location: location
}

resource aks 'Microsoft.ContainerService/managedClusters@2023-05-02-preview' = {
  name: clusterName
  location: location
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: {
      '${managedIdentity.id}': {}
    }
  }
  properties: {
    kubernetesVersion: kubernetesVersion
    dnsPrefix: clusterName
    enableRBAC: true
    agentPoolProfiles: [
      {
        name: 'nodepool1'
        count: nodeCount
        vmSize: vmSize
        mode: 'System'
        osType: 'Linux'
        osSKU: 'AzureLinux'
      }
      {
        name: 'gpu1'
        count: 1
        vmSize: gpu1VmSize
        mode: 'User'
        osType: 'Linux'
        osSKU: 'AzureLinux'
        nodeTaints: [
          'sku=gpu:NoSchedule'
        ]
        enableAutoScaling: true
        minCount: 0
        maxCount: 1
      }
      {
        name: 'gpu2'
        count: 1
        vmSize: gpu2VmSize
        mode: 'User'
        osType: 'Linux'
        osSKU: 'AzureLinux'
        nodeTaints: [
          'sku=gpu:NoSchedule'
        ]
        enableAutoScaling: true
        minCount: 0
        maxCount: 1
      }
    ]
  }
}

resource containerRegistry 'Microsoft.ContainerRegistry/registries@2019-05-01' = {
  name: 'acr${rand}'
  location: location
  sku: {
    name: 'Standard'
  }
  properties: {
    adminUserEnabled: true
  }
}

resource storageAccount 'Microsoft.Storage/storageAccounts@2021-02-01' = {
  name: 'storage${rand}'
  location: location
  kind: 'BlockBlobStorage'
  sku: {
    name: 'Premium_LRS'
  }
  properties: {
    minimumTlsVersion: 'TLS1_2'
  }
}

// via: https://docs.microsoft.com/en-us/azure/azure-resource-manager/bicep/bicep-functions-resource#subscriptionresourceid-example
var roleDefinitionId = {
  Owner: '8e3af657-a8ff-443c-a75c-2fe8c4bcb635'
  Contributor: 'b24988ac-6180-42a0-ab88-20f7382dd24c'
  Reader: 'acdd72a7-3385-48ef-bd42-f606fba81ae7'
  AcrPull: '7f951dda-4ed3-4680-a7ca-43fe172d538d'
  StorageBlobDataContributor: 'ba92f5b4-2d11-453d-a403-e96b0029c9fe'
  KubernetesServiceClusterUserRole: '4abbcc35-e782-43d8-92c5-2d3f1bd2253f'
}

// https://github.com/Azure/bicep/discussions/3181
var roleAssignmentAcrDefinition = 'AcrPull'
resource roleAssignmentAcr 'Microsoft.Authorization/roleAssignments@2020-08-01-preview' = {
  name: guid(containerRegistry.id, roleAssignmentAcrDefinition)
  scope: containerRegistry
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', roleDefinitionId[roleAssignmentAcrDefinition])
    principalId: aks.properties.identityProfile.kubeletidentity.objectId
  }
}

var roleAssignmentStorageAccountDefinition = 'StorageBlobDataContributor'
resource roleAssignmentStorageAccount 'Microsoft.Authorization/roleAssignments@2020-08-01-preview' = {
  name: guid(storageAccount.id, roleAssignmentStorageAccountDefinition)
  scope: storageAccount
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', roleDefinitionId[roleAssignmentStorageAccountDefinition])
    principalId: managedIdentity.properties.principalId
  }
  dependsOn: [
    aks
  ]
}
