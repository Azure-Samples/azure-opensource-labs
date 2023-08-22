@description('Location for all resources.')
param location string = resourceGroup().location

@description('The name of your Virtual Machine.')
param vmName string = 'vm1'

@description('The Virtual Machine size.')
@allowed([
  'Standard_B1ls'
  'Standard_B1s'
  'Standard_B2s'
  'Standard_B1ms'
  'Standard_B2ms'
  'Standard_B4ms'
  'Standard_D2s_v5'
  'Standard_D4s_v5'
  'Standard_D2ps_v5'
  'Standard_D4ps_v5'
  'Standard_NC4as_T4_v3'
])
param vmSize string = 'Standard_B2s'

@description('The Storage Account Type for OS and Data disks.')
@allowed([
  'Standard_LRS'
  'Premium_LRS'
  'UltraSSD_LRS'
])
param diskAccountType string = 'Premium_LRS'

@description('The OS Disk size.')
@allowed([
  1024
  512
  256
  128
  64
  32
])
param osDiskSize int = 256

@description('The OS image for the VM.')
@allowed([
  'mariner-gen2'
  'mariner-gen1'
  'mariner-arm'
])
param osImage string = 'mariner-gen2'

@description('Name of the VNET.')
param virtualNetworkName string = ''

@description('Default IP to allow Port 22 (SSH). Set to your own IP Address.')
param allowIpPort22 string = '127.0.0.1'

@description('Username for the Virtual Machine.')
param adminUsername string = 'azureuser'

@secure()
@description('SSH Key for the Virtual Machine.')
param sshKey string = ''

@description('User data for deployment.')
param userData string = ''

@description('Deploy with cloud-init.')
@allowed([
  'cloud-init'
  'none'
])
param customData string = 'none'

@description('Environment variables as JSON object.')
@secure()
param env object = {}

var rand = substring(uniqueString(resourceGroup().id), 0, 6)
var vnetName = virtualNetworkName != '' ? virtualNetworkName : '${resourceGroup().name}-vnet'
var subnetName = 'default'
var keyData = sshKey != '' ? sshKey : 'ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQC3gkRpKwprN00sT7yekr0xO0F+uTllDua02puhu1v0zGu3aENvUsygBHJiTy+flgrO2q3mY9F5/D67+WHDeSpr5s71UtnbzMxTams89qmo+raTm+IqjzdNujaWf0/pbT6JUkQq0fR0BfIvg3/7NTXhlzjmCOP2EpD91LzN6b5jAm/5hXr0V5mcpERo8kk2GWxjKmwmDOV+huH1DIFDpMxT3WzR2qvZp1DZbNSYmKkrite3FHlPGLXA1I3bRQT+iTj8vRGpxOPSiMdPK4RNMEZVXSGQ3OZbSl2FBCbd/tdJ1idKo8/ZCkHxdh9/em28/yfPUK0D164shgiEdIkdOQJv'
var publicIPAddressName = '${vmName}-ip'
var networkInterfaceName = '${vmName}-nic'
var ipConfigName = '${vmName}-ipconfig'
var subnetAddressPrefix = '10.1.0.0/24'
var addressPrefix = '10.1.0.0/16'

var customDataCloudInit = '''
#cloud-config
# vim: syntax=yaml

write_files:
- path: /home/azureuser/env.json
  content: {0}
  encoding: b64

runcmd:
- cd /home/azureuser/
- chown -R azureuser:azureuser /home/azureuser/
- sudo tdnf install -y moby-engine moby-cli ca-certificates
- sudo systemctl enable docker.service
- sudo systemctl daemon-reload
- sudo systemctl start docker.service
- sudo -u azureuser echo $(date) > hello.txt
'''

var customDataCloudInitFormat = format(customDataCloudInit, base64(string(env)))

var kvCustomData = {
  none: null
  'cloud-init': base64(customDataCloudInitFormat)
}

var kvVmSizeImageReference = {
  Standard_D2ps_v5:'mariner-arm'
  Standard_D4ps_v5:'mariner-arm'
}

var kvImageReference = {
  'mariner-gen1': {
    publisher: 'MicrosoftCBLMariner'
    offer: 'cbl-mariner'
    sku: 'cbl-mariner-2'
    version: 'latest'
  }
  'mariner-gen2': {
    publisher: 'MicrosoftCBLMariner'
    offer: 'cbl-mariner'
    sku: 'cbl-mariner-2-gen2'
    version: 'latest'
  }
  'mariner-arm': {
    publisher: 'MicrosoftCBLMariner'
    offer: 'cbl-mariner'
    sku: 'cbl-mariner-2-arm64'
    version: 'latest'
  }
}

var imageReference = contains(kvVmSizeImageReference, vmSize) ? kvImageReference[kvVmSizeImageReference[vmSize]] : kvImageReference[osImage]

// Base network security group rules
var nsgSecurityRulesBase = [
  {
    name: 'Port_22'
    properties: {
      priority: 100
      protocol: 'Tcp'
      access: 'Allow'
      direction: 'Inbound'
      sourceAddressPrefix: allowIpPort22
      sourcePortRange: '*'
      destinationAddressPrefix: '*'
      destinationPortRange: '22'
    }
  }
  {
    name: 'Port_80'
    properties: {
      protocol: '*'
      sourcePortRange: '*'
      destinationPortRange: '80'
      sourceAddressPrefix: 'Internet'
      destinationAddressPrefix: '*'
      access: 'Allow'
      priority: 110
      direction: 'Inbound'
    }
  }
  {
    name: 'Port_443'
    properties: {
      protocol: '*'
      sourcePortRange: '*'
      destinationPortRange: '443'
      sourceAddressPrefix: 'Internet'
      destinationAddressPrefix: '*'
      access: 'Allow'
      priority: 120
      direction: 'Inbound'
    }
  }
  {
    name: 'Port_8080'
    properties: {
      protocol: '*'
      sourcePortRange: '*'
      destinationPortRange: '8080'
      sourceAddressPrefix: 'Internet'
      destinationAddressPrefix: '*'
      access: 'Allow'
      priority: 130
      direction: 'Inbound'
    }
  }
  {
    name: 'Port_41641'
    properties: {
      protocol: 'Udp'
      sourcePortRange: '*'
      destinationPortRange: '41641'
      sourceAddressPrefix: 'Internet'
      destinationAddressPrefix: '*'
      access: 'Allow'
      priority: 140
      direction: 'Inbound'
    }
  }
]

var nsgSecurityRules = nsgSecurityRulesBase

resource identityName 'Microsoft.ManagedIdentity/userAssignedIdentities@2018-11-30' = {
  name: '${resourceGroup().name}-identity'
  location: location
}

resource nic 'Microsoft.Network/networkInterfaces@2021-05-01' = {
  name: networkInterfaceName
  location: location
  properties: {
    ipConfigurations: [
      {
        name: ipConfigName
        properties: {
          subnet: {
            #disable-next-line use-resource-id-functions
            id: '/subscriptions/${subscription().subscriptionId}/resourceGroups/${resourceGroup().name}/providers/Microsoft.Network/virtualNetworks/${vnetName}/subnets/${subnetName}'
          }
          privateIPAllocationMethod: 'Dynamic'
          publicIPAddress: { id: publicIP.id }
        }
      }
    ]
    networkSecurityGroup: {
      id: nsg.id
    }
  }
}

resource nsg 'Microsoft.Network/networkSecurityGroups@2021-05-01' = {
  name: '${resourceGroup().name}-nsg'
  location: location
  properties: {
    securityRules: nsgSecurityRules
  }
}

resource vnet 'Microsoft.Network/virtualNetworks@2021-05-01' = if (virtualNetworkName == '') {
  name: vnetName
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [
        addressPrefix
      ]
    }
    subnets: [
      {
        name: subnetName
        properties: {
          addressPrefix: subnetAddressPrefix
          privateEndpointNetworkPolicies: 'Enabled'
          privateLinkServiceNetworkPolicies: 'Enabled'
        }
      }
      {
        name: 'AzureBastionSubnet'
        properties: {
          addressPrefix: '10.1.1.0/26'
          privateEndpointNetworkPolicies: 'Enabled'
          privateLinkServiceNetworkPolicies: 'Enabled'
        }
      }
    ]
  }
}

resource publicIP 'Microsoft.Network/publicIPAddresses@2021-05-01' = {
  name: publicIPAddressName
  location: location
  sku: {
    name: 'Standard'
  }
  properties: {
    publicIPAllocationMethod: 'Static'
    dnsSettings: {
      domainNameLabel: toLower('${vmName}-${rand}')
    }
  }
}

resource vm 'Microsoft.Compute/virtualMachines@2021-11-01' = {
  name: vmName
  location: location
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: {
      '${identityName.id}': {}
    }
  }
  properties: {
    userData: userData
    hardwareProfile: {
      vmSize: vmSize
    }
    storageProfile: {
      osDisk: {
        managedDisk: {
          storageAccountType: diskAccountType
        }
        name: '${vmName}-osdisk1'
        diskSizeGB: osDiskSize
        createOption: 'FromImage'
      }
      imageReference: imageReference
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: nic.id
        }
      ]
    }
    osProfile: {
      computerName: vmName
      customData: kvCustomData[customData]
      adminUsername: adminUsername
      linuxConfiguration: {
        disablePasswordAuthentication: true
        ssh: {
          publicKeys: [
            {
              keyData: keyData
              path: '/home/${adminUsername}/.ssh/authorized_keys'
            }
          ]
        }
      }
    }
  }
}

output adminUsername string = adminUsername
output hostname string = publicIP.properties.dnsSettings.fqdn
output sshCommand string = 'ssh ${adminUsername}@${publicIP.properties.dnsSettings.fqdn}'
