targetScope = 'subscription'

param name string
param location string
param tags object = {}

param kubernetesVersion string = '1.29'
param systemNodeCount int = 3
param systemNodeSize string = 'Standard_D4s_v5'

param userObjectId string
// param dnsName string

var networkPlugin = 'kubenet'
var networkPolicy = 'calico'

// Set up the resource group
resource rg 'Microsoft.Resources/resourceGroups@2021-04-01' = {
  name: 'rg-${name}'
  location: location
  tags: tags
}

module kv '../../bicep/modules/azure-key-vault/main.bicep' = {
  scope: rg
  name: 'akvDeploy'
  params: {
    location: location
    name: 'akv-${name}'
    sku: 'standard'
    tags: tags
    userObjectId: userObjectId
    tenantId: tenant().tenantId
  }
}

// Setup the log analytics workspace
module law '../../bicep/modules/azure-log-analytics-workspace/main.bicep' = {
  scope: rg
  name: 'lawDeploy'
  params: {
    name: 'law-${name}'
    location: location
    tags: tags
  }
}

// Setup the Kubernetes cluster
module aks '../../bicep/modules/azure-kubernetes-service/main.bicep' = {
  scope: rg
  name: 'aksDeploy'
  params: {
    name: 'aks-${name}'
    location: location
    tags: tags
    slaTier: 'Free'
    managedIdentityType: 'SystemAssigned'
    kubernetesVersion: kubernetesVersion
    networkPlugin: networkPlugin
    networkPolicy: networkPolicy
    loadBalancerSku: 'Standard'
    outboundType: 'loadBalancer'
    dnsServiceIP: '10.0.0.10'
    podCidrs: [
      '10.244.0.0/16'
    ]
    serviceCidrs: [
      '10.0.0.0/16'
    ]
    ipFamilies: [
      'IPv4'
    ]
    defenderEnabled: false
    imageCleanerEnabled: false
    systemNodeCount: systemNodeCount
    systemNodeVmSize: systemNodeSize
    // registryName: acr.outputs.name
    addonProfiles: {
      omsagent: {
        config: {
          logAnalyticsWorkspaceResourceID: law.outputs.id
        }
        enabled: true
      }
    }
  }
}

// Deploy the key vault secrets provider add-on
module aksAddonKv '../../bicep/modules/azure-kubernetes-service-addons/main.bicep' = {
  scope: rg
  name: 'aksAddonKvDeploy'
  params: {
    location: location
    clusterId: aks.outputs.id
    addonProfiles: {
      azureKeyvaultSecretsProvider: {
        config: {
          enableSecretRotation: 'true'
          rotationPollInterval: '2m'
        }
        enabled: true
      }
    }
  }
  dependsOn: [
    aks
    kv
  ]
}

// Deploy the web app routing add-on
module aksAddonIng '../../bicep/modules/azure-kubernetes-service-ingress/main.bicep' = {
  scope: rg
  name: 'aksAddonIngDeploy'
  params: {
    location: location
    clusterId: aks.outputs.id
  }
  dependsOn: [
    aksAddonKv
  ]
}

// Deploy the open service mesh add-on
module aksAddonOsm '../../bicep/modules/azure-kubernetes-service-addons/main.bicep' = {
  scope: rg
  name: 'aksAddonOsmDeploy'
  params: {
    location: location
    clusterId: aks.outputs.id
    addonProfiles: {
      openServiceMesh: {
        config: {}
        enabled: true
      }
    }
  }
  dependsOn: [
    aksAddonIng
  ]
}
