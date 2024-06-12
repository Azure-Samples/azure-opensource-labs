targetScope = 'subscription'

param name string
param location string
param tags object = {}
param kubernetesVersion string = '1.24.3'
param systemNodeCount int = 3
param systemNodeSize string = 'Standard_D4s_v5'
param userObjectId string
param dnsName string

var networkPlugin = 'kubenet'
var networkPolicy = 'calico'

// Deploy the resource group
resource rg 'Microsoft.Resources/resourceGroups@2021-04-01' = {
  name: 'rg-${name}'
  location: location
  tags: tags
}

// Deploy the Kubernetes cluster
module aks '../../bicep/modules/azure-kubernetes-service/main.bicep' = {
  scope: rg
  name: 'aksDeploy'
  params: {
    name: 'aks-${name}'
    location: location
    tags: tags
    kubernetesVersion: kubernetesVersion
    networkPlugin: networkPlugin
    networkPolicy: networkPolicy
    systemNodeCount: systemNodeCount
    systemNodeVmSize: systemNodeSize
  }
}

// Deploy the key vault
module kv '../../bicep/modules/azure-key-vault/main.bicep' = {
  scope: rg
  name: 'kvDeploy'
  params: {
    location: location
    name: 'akv-${name}'
    sku: 'standard'
    tags: tags
    userObjectId: userObjectId
    tenantId: tenant().tenantId
    accessPolicies: [
      {
        objectId: aks.outputs.kubeletIdentityObjectId
        permissions: {
          certificates: [
            'get'
          ]
          secrets: [
            'get'
          ]
        }
        tenantId: tenant().tenantId
      }
    ]
  }

  dependsOn: [
    aks
  ]
}

// Deploy the public DNS zone
module dns '../../bicep/modules/azure-dns/main.bicep' = {
  scope: rg
  name: 'dnsDeploy'
  params: {
    location: 'Global'
    name: dnsName
    tags: tags
    zoneType: 'Public'
    // assignDnsZoneContributor: aks.outputs.kubeletIdentityObjectId
  }

  dependsOn: [
    aks
  ]
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
    dnsZoneResourceId: dns.outputs.id
  }
  dependsOn: [
    aksAddonKv
  ]
}

// todo: troubleshoot this
// var mcResourceGroup = resourceGroup(aks.outputs.nodeResourceGroupName)
// resource userAssignedIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2022-01-31-preview' existing = {
//   name: 'webapprouting-${aks.outputs.name}'
//   scope: mcResourceGroup
// }

// module aksAddonIngDns '../../bicep/modules/azure-kubernetes-service-ingress-dns/main.bicep' = {
//   scope: rg
//   name: 'aksAddonIngDnsDeploy'
//   params: {
//     dnsZoneName: dns.outputs.name
//     principalId: userAssignedIdentity.properties.principalId
//   }
//   dependsOn: [
//     aksAddonIng
//   ]
// }
