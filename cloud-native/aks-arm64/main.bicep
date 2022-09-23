targetScope = 'subscription'

param name string
param location string
param tags object = {}

var networkPlugin = 'kubenet'
var networkPolicy = 'calico'

// Set up the resource group
resource rg 'Microsoft.Resources/resourceGroups@2021-04-01' = {
  name: 'rg-${name}'
  location: location
  tags: tags
}

// Set up the container registry
module acr 'br/oss-labs:bicep/modules/azure-container-registry:v0.1' = {
  scope: rg
  name: 'acrDeploy'
  params: {
    name: 'acr${toLower(name)}'
    location: location
    tags: tags
    sku: 'Basic'
    adminUserEnabled: true
    managedIdentityType: 'SystemAssigned'
    publicNetworkAccess: true
  }
}

// Set up the network security group
module nsg 'br/oss-labs:bicep/modules/azure-network-security-group:v0.1' = if (networkPlugin != 'kubenet') {
  scope: rg
  name: 'nsgDeploy'
  params: {
    name: 'nsg-${name}'
    location: location
    tags: tags
  }
}

// Setup the virtual network and subnet
module vnet 'br/oss-labs:bicep/modules/azure-virtual-network:v0.1' = if (networkPlugin != 'kubenet') {
  scope: rg
  name: 'vnetDeploy'
  params: {
    name: 'vnet-${name}'
    location: location
    tags: tags
    vnetAddressPrefix: '10.21.0.0/16'
    snetName: 'snet-${name}'
    snetAddressPrefix: '10.21.0.0/24'
    networkSecurityGroupId: networkPlugin != 'kubenet' ? nsg.outputs.id : ''
    dnsServer: '' // Leave empty if you want to use Azure's default DNS
  }
}

// Setup the log analytics workspace
module law 'br/oss-labs:bicep/modules/azure-log-analytics-workspace:v0.1' = {
  scope: rg
  name: 'lawDeploy'
  params: {
    name: 'law-${name}'
    location: location
    tags: tags
  }
}

// Setup the Kubernetes cluster
module aks 'br/oss-labs:bicep/modules/azure-kubernetes-service:v0.1' = {
  scope: rg
  name: 'aksDeploy'
  params: {
    name: 'aks-${name}'
    location: location
    tags: tags
    slaTier: 'Free'
    managedIdentityType: 'SystemAssigned'
    kubernetesVersion: '1.24.3'
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
    systemNodeCount: 2
    systemNodeVmSize: 'Standard_D2s_v5'
    registryName: acr.outputs.name
    vnetSubnetID: networkPlugin != 'kubenet' ? vnet.outputs.subnetId : ''
    logAnalyticsWorkspaceResourceID: law.outputs.id
  }
}

// Setup the user node pools and deploy into a subnet
module armpool 'br/oss-labs:bicep/modules/azure-kubernetes-service-nodepools:v0.1' = {
  scope: rg
  name: 'armNodePoolsDeploy'
  params: {
    managedClusterName: aks.outputs.name
    userNodes: [
      {
        name: 'arm64'
        mode: 'User'
        vmSize: 'Standard_D4pds_v5' // Make sure the SKU is available in your region.
        enableAutoScaling: true
        scaleDownMode: 'Deallocate' // Delete is the default.
        minCount: 0 // If autoscale is enabled, then set the min number of nodes you wish to run.
        maxCount: 3 // Set this to the maximum number of nodes to run. If autoscale is not enabled, this value will be used as the node count.
        type: 'VirtualMachineScaleSets' // If autoscale is enabled, then the node type must be VirtualMachineScaleSets (default is AvailabilitySet).
        osDiskType: 'Managed' // If autoscale is enabled and scale down mode is set to Deallocate, then the OS disk must be managed (default is Ephemeral).
        nodeTaints: '' // Add a taint like this `key=value:NoSchedule` or leave as empty string to not taint your nodes
        vnetSubnetID: networkPlugin != 'kubenet' ? vnet.outputs.subnetId : '' // If the cluster is using azure network plugin, then you can pass in the subnet resource ID like this `vnet.outputs.subnetId`; otherwise, leave it empty
      }
    ]
  }
}
