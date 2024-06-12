param name string
param location string
param tags object

@allowed([
  'Free'
  'Paid'
])
@description('Defaults to Free tier')
param slaTier string = 'Free'

@allowed([
  'SystemAssigned'
  'UserAssigned'
])
@description('Two options are available: SystemAssigned or UserAssigned')
param managedIdentityType string = 'SystemAssigned'

@description('Required when managed identity type is set to UserAssigned')
param userAssignedIdentities object = {}

@description('Default is 1.29')
param kubernetesVersion string = '1.29'

param defenderEnabled bool = false

param imageCleanerEnabled bool = false
param imageCleanerIntervalHours int = 12

param systemNodeCount int = 3

@description('Default system node pool size is Standard_D2s_v5')
param systemNodeVmSize string = 'Standard_D2s_v5'

@description('Optional parameter to attach AKS cluster to an existing ACR')
param registryName string = ''

@allowed([
  'kubenet'
  'azure'
  'none'
])
@description('Network plugin used for building the Kubernetes network.')
param networkPlugin string = 'kubenet'

@allowed([
  'calico'
  'azure'
])
@description('Network policy used for building the Kubernetes network.')
param networkPolicy string = 'calico'

@allowed([
  'Standard'
  'Basic'
])
@description('The default is standard.')
param loadBalancerSku string = 'Standard'

@description('An IP address assigned to the Kubernetes DNS service. It must be within the Kubernetes service address range specified in serviceCidr.')
param dnsServiceIP string = '10.0.0.10'

@description('A CIDR notation IP range assigned to the Docker bridge network. It must not overlap with any Subnet IP ranges or the Kubernetes service address range.')
param dockerBridgeCidr string = '172.17.0.1/16'

@description('Resource ID of log analytics workspace for auditing')
param logAnalyticsWorkspaceResourceId string = ''

@allowed([
  'loadBalancer'
  'managedNATGateway'
  'userAssignedNATGateway'
  'userDefinedRouting'
])
@description('This can only be set at cluster creation time and cannot be changed later.')
param outboundType string = 'loadBalancer'

@description('One IPv4 CIDR is expected for single-stack networking. Two CIDRs, one for each IP family (IPv4/IPv6), is expected for dual-stack networking.')
param podCidrs array = [
  '10.244.0.0/16'
]

@description('One IPv4 CIDR is expected for single-stack networking. Two CIDRs, one for each IP family (IPv4/IPv6), is expected for dual-stack networking. They must not overlap with any Subnet IP ranges.')
param serviceCidrs array = [
  '10.0.0.0/16'
]

@allowed([
  'IPv4'
  'IPv6'
])
param ipFamilies array = [
  'IPv4'
]

@description('If the cluster is using azure network plugin, then you can pass in the subnet resource ID like this `vnet.outputs.subnetId`; otherwise, leave it empty')
param vnetSubnetID string = ''

@description('Enable nodeTaints on the system node pool (e.g., [\'CriticalAddonsOnly=true:NoSchedule\'])')
param nodeTaints array = []

@description('AKS addons to enable')
param addonProfiles object = {}

param enablePrometheusMetrics bool = false
param prometheusMetricLabelsAllowlist string = ''
param prometheusMetricAnnotationsAllowList string = ''

resource managedCluster 'Microsoft.ContainerService/managedClusters@2022-08-03-preview' = {
  name: name
  location: location
  tags: tags
  sku: {
    name: 'Basic'
    tier: slaTier
  }
  identity: {
    type: managedIdentityType
    userAssignedIdentities: managedIdentityType == 'UserAssigned' ? userAssignedIdentities : null
  }
  properties: {
    kubernetesVersion: kubernetesVersion
    dnsPrefix: name
    azureMonitorProfile: enablePrometheusMetrics ? {
      metrics: {
        enabled: true // Requires Microsoft.ContainerService/AKS-PrometheusAddonPreview
        kubeStateMetrics: {
          metricLabelsAllowlist: prometheusMetricLabelsAllowlist
          metricAnnotationsAllowList: prometheusMetricAnnotationsAllowList
        }
      }
    } : null
    networkProfile: {
      networkPlugin: networkPlugin
      networkPolicy: networkPolicy
      loadBalancerSku: loadBalancerSku
      dnsServiceIP: dnsServiceIP
      dockerBridgeCidr: dockerBridgeCidr
      outboundType: outboundType
      podCidrs: podCidrs
      serviceCidrs: serviceCidrs
      ipFamilies: ipFamilies
    }
    agentPoolProfiles: [
      {
        name: 'system'
        count: systemNodeCount
        vmSize: systemNodeVmSize
        mode: 'System'
        vnetSubnetID: empty(vnetSubnetID) ? null : vnetSubnetID
        nodeTaints: empty(nodeTaints) ? null : nodeTaints
      }
    ]
    securityProfile: {
      defender: {
        securityMonitoring: {
          enabled: defenderEnabled
        }
      }
      imageCleaner: {
        enabled: imageCleanerEnabled
        intervalHours: imageCleanerIntervalHours
      }
    }
    addonProfiles: addonProfiles
  }
}

// Get the registry by name
resource registry 'Microsoft.ContainerRegistry/registries@2022-02-01-preview' existing = if (registryName != '') {
  name: registryName
}

// Get the role definition resource by name, to find the name for the role AcrPull, you can look 
// it up at the following url: https://learn.microsoft.com/en-us/azure/role-based-access-control/built-in-roles#acrpull
resource acrPullRoleDefinition 'Microsoft.Authorization/roleDefinitions@2022-04-01' existing = if (registryName != '') {
  scope: subscription()
  name: '7f951dda-4ed3-4680-a7ca-43fe172d538d'
}

// Give the kubelet user assigned managed identity the AcrPull permissions to pull containers from ACR
resource acrPullRoleAssignments 'Microsoft.Authorization/roleAssignments@2022-04-01' = if (registryName != '') {
  name: guid(managedCluster.id, registryName)
  scope: registry
  properties: {
    principalId: managedCluster.properties.identityProfile.kubeletidentity.objectId
    roleDefinitionId: acrPullRoleDefinition.id
  }
}

// Get the role definition resource by name, to find the name for the role Contributor, you can look 
// it up at the following url: https://learn.microsoft.com/en-us/azure/role-based-access-control/built-in-roles#contributor
resource contributorRoleDefinition 'Microsoft.Authorization/roleDefinitions@2022-04-01' existing = {
  scope: subscription()
  name: 'b24988ac-6180-42a0-ab88-20f7382dd24c'
}

// Give the managedCluster identity the Contributor permissions
resource contribtorRoleAssignments 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(managedCluster.id, resourceGroup().id)
  scope: resourceGroup()
  properties: {
    principalId: managedCluster.identity.principalId
    roleDefinitionId: contributorRoleDefinition.id
  }
}

output name string = managedCluster.name
output id string = managedCluster.id
output kubeletIdentityObjectId string = managedCluster.properties.identityProfile.kubeletidentity.objectId
output nodeResourceGroupName string = managedCluster.properties.nodeResourceGroup
