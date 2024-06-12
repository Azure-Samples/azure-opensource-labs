param location string = resourceGroup().location
param clusterName string = ''
param nodeCount int = 1
param vmSize string = 'standard_d2s_v3'
param kubernetesVersion string = '1.29'

var rand = substring(uniqueString(resourceGroup().id), 0, 6)
var clusterName_var = clusterName != '' ? clusterName : 'aks1'

resource managedIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2018-11-30' = {
  name: '${resourceGroup().name}-identity'
  location: location
}

resource aks 'Microsoft.ContainerService/managedClusters@2021-05-01' = {
  name: clusterName_var
  location: location
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: {
      '${managedIdentity.id}': {}
    }
  }
  properties: {
    kubernetesVersion: kubernetesVersion
    dnsPrefix: clusterName_var
    enableRBAC: true
    agentPoolProfiles: [
      {
        name: 'pool0'
        count: nodeCount
        vmSize: vmSize
        mode: 'System'
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

resource serviceBus 'Microsoft.ServiceBus/namespaces@2021-06-01-preview' = {
  name: 'servicebus${rand}'
  location: location
  sku: {
    capacity: 1
    name: 'Standard'
    tier: 'Standard'
  }
  properties: {
    disableLocalAuth: false
  }
}

// via: https://docs.microsoft.com/en-us/azure/azure-resource-manager/bicep/bicep-functions-resource#subscriptionresourceid-example
var roleDefinitionId = {
  Owner: '8e3af657-a8ff-443c-a75c-2fe8c4bcb635'
  Contributor: 'b24988ac-6180-42a0-ab88-20f7382dd24c'
  Reader: 'acdd72a7-3385-48ef-bd42-f606fba81ae7'
  AcrPull: '7f951dda-4ed3-4680-a7ca-43fe172d538d'
  StorageBlobDataContributor: 'ba92f5b4-2d11-453d-a403-e96b0029c9fe'
  ServiceBusDataOwner: '090c5cfd-751d-490a-894a-3ce6f1109419'
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

var roleAssignmentServiceBusDefinition = 'ServiceBusDataOwner'
resource roleAssignmentServiceBus 'Microsoft.Authorization/roleAssignments@2020-08-01-preview' = {
  name: guid(serviceBus.id, roleAssignmentServiceBusDefinition)
  scope: serviceBus
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', roleDefinitionId[roleAssignmentServiceBusDefinition])
    principalId: managedIdentity.properties.principalId
  }
  dependsOn: [
    aks
  ]
}

resource managedIdentityDeploy 'Microsoft.ManagedIdentity/userAssignedIdentities@2018-11-30' = {
  name: '${resourceGroup().name}-identity-deploy'
  location: location
}

var roleAssignmentDeploymentContributorDefinition = 'Contributor'
resource roleAssignmentDeploymentContributor 'Microsoft.Authorization/roleAssignments@2020-08-01-preview' = {
  name: guid(managedIdentityDeploy.id, roleAssignmentDeploymentContributorDefinition)
  scope: resourceGroup()
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', roleDefinitionId[roleAssignmentDeploymentContributorDefinition])
    principalId: managedIdentityDeploy.properties.principalId
  }
  dependsOn: [
    aks
  ]
}
