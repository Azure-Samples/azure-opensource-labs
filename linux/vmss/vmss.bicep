@description('Name for the Virtual Machine, also used as prefix for various resources.')
param vmssName string = 'vmss1'

@description('User name for the Virtual Machine.')
param adminUsername string = 'azureuser'

@description('Type of authentication to use on the Virtual Machine. SSH key is recommended.')
@allowed([
  'sshPublicKey'
  'password'
])
param authenticationType string = 'sshPublicKey'

@description('SSH Key or password for the Virtual Machine. SSH key is recommended.')
@secure()
param adminPasswordOrKey string = 'ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQC3gkRpKwprN00sT7yekr0xO0F+uTllDua02puhu1v0zGu3aENvUsygBHJiTy+flgrO2q3mY9F5/D67+WHDeSpr5s71UtnbzMxTams89qmo+raTm+IqjzdNujaWf0/pbT6JUkQq0fR0BfIvg3/7NTXhlzjmCOP2EpD91LzN6b5jAm/5hXr0V5mcpERo8kk2GWxjKmwmDOV+huH1DIFDpMxT3WzR2qvZp1DZbNSYmKkrite3FHlPGLXA1I3bRQT+iTj8vRGpxOPSiMdPK4RNMEZVXSGQ3OZbSl2FBCbd/tdJ1idKo8/ZCkHxdh9/em28/yfPUK0D164shgiEdIkdOQJv'

@description('Default IP to allow Port 22 (SSH). Set to your own IP Address')
param allowIpPort22 string = '127.0.0.1'

@description('Unique DNS Name for the Public IP used to access the Virtual Machine.')
param dnsPrefix string = ''

@description('The Virtual Machine size.')
@allowed([
  'Standard_B1ls'
  'Standard_B1s'
  'Standard_B1ms'
  'Standard_B2s'
  'Standard_F1s'
  'Standard_DS1_v2'
  'Standard_B2ms'
  'Standard_F2s_v2'
  'Standard_D2s_v3'
  'Standard_D2ds_v4'
  'Standard_F2s'
  'Standard_E2s_v3'
  'Standard_DS2_v2'
  'Standard_DS3_v2'
  'Standard_DS4_v2'
  'Standard_B4ms'
])
param vmSize string = 'Standard_D2ds_v4'

@description('The OS Disk size.')
@allowed([
  1024
  512
  256
  128
  64
  32
])
param osDiskSize int = 1024

@description('The Data Disk size.')
@allowed([
  1024
  512
  256
  128
  0
])
param dataDiskSize int = 0

@description('The Storage Account Type for OS and Data disks.')
@allowed([
  'Premium_LRS'
  'UltraSSD_LRS'
])
param diskAccountType string = 'Premium_LRS'

@description('The OS version for the VM.')
@allowed([
  'Canonical'
  'MicrosoftWindowsDesktop'
])
param osPublisher string = 'Canonical'

@description('The OS offer for the VM.')
@allowed([
  'UbuntuServer'
  'Windows-10'
])
param osOffer string = 'UbuntuServer'

@description('The OS sku for the VM.')
@allowed([
  '18.04-LTS'
  '16.04.0-LTS'
  '19h1-pro'
])
param osSku string = '18.04-LTS'

@description('Location for all resources.')
param location string = resourceGroup().location

@description('URL to cloud-init script')
param customDataUrl string = ''

@description('Environment variables as JSON object')
param env object = {}

@description('Number of VM instances (1000 or less).')
@maxValue(1000)
param instanceCount int = 1

@description('Tier')
@allowed([
  'Standard'
  'Basic'
])
param vmssTier string = 'Standard'

@description('Priority')
@allowed([
  'Regular'
  'Low'
  'Spot'
])
param vmssPriority string = 'Regular'

@description('Eviction Policy')
@allowed([
  'Deallocate'
  'Delete'
])
param vmssEvictionPolicy string = 'Deallocate'

var env_var = env
var customDataUrl_var = customDataUrl
var customDataAdvanced = base64('#cloud-config\n# vim: syntax=yaml\n\npackages:\n- docker.io\n- jq\n\n# create the docker group\ngroups:\n  - docker\n\n# Add default auto created user to docker group\nsystem_info:\n  default_user:\n    groups: [docker]\n\nwrite_files:\n\n- encoding: b64\n  content: ${base64(string(env_var))}\n  path: /home/azureuser/env.json\n\nruncmd:\n- cd /home/azureuser/\n- $( cat env.json | jq -r \'keys[] as $k | "export \\($k)=\\(.[$k])"\' )\n- curl -L -o cloud-init.sh \'${customDataUrl_var}\'\n- bash cloud-init.sh 2>&1 | tee cloud-init.log\n')
var customData = base64('#include\n${customDataUrl}')
var addressPrefix = '10.0.0.0/16'
var bePoolName = '${vmssName}-bepool'
var dnsPrefix_var = ((dnsPrefix == '') ? '${vmssName}-${uniqueString(resourceGroup().id)}' : dnsPrefix)
var frontEndIPConfigID = resourceId('Microsoft.Network/loadBalancers/frontendIpConfigurations', loadBalancerName, 'LoadBalancerFrontend')
var identityName_var = '${resourceGroup().name}-identity'
var imageOffer = osOffer
var imagePublisher = osPublisher
var imageSku = osSku
var ipConfigName = '${vmssName}-ipconfig'
var loadBalancerName = '${vmssName}-lb'
var natBackendPort = 22
var natEndPort = 50119
var natPoolName = '${vmssName}-natpool'
var natStartPort = 50000
var nicName = '${vmssName}-nic'
var publicIPAddressID = publicIPAddressName.id
var publicIPAddressName_var = '${vmssName}-ip'
var publicIPAddressType = 'Static'
var subnetName = 'default'
var subnetPrefix = '10.0.0.0/24'
var virtualNetworkName_var = '${resourceGroup().name}-vnet'
var nsgName_var = '${resourceGroup().name}-nsg'
var vmssName_var = vmssName

resource identityName 'Microsoft.ManagedIdentity/userAssignedIdentities@2018-11-30' = {
  name: identityName_var
  location: location
}

resource publicIPAddressName 'Microsoft.Network/publicIPAddresses@2020-05-01' = {
  name: publicIPAddressName_var
  location: location
  sku: {
    name: 'Standard'
  }
  properties: {
    publicIPAllocationMethod: publicIPAddressType
    dnsSettings: {
      domainNameLabel: dnsPrefix_var
    }
  }
}

resource virtualNetworkName 'Microsoft.Network/virtualNetworks@2018-11-01' = {
  name: virtualNetworkName_var
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
          addressPrefix: subnetPrefix
          networkSecurityGroup: {
            id: nsgName.id
          }
        }
      }
    ]
  }
}

resource nsgName 'Microsoft.Network/networkSecurityGroups@2018-12-01' = {
  name: nsgName_var
  location: location
  properties: {
    securityRules: [
      {
        name: 'Port_22'
        properties: {
          protocol: '*'
          sourcePortRange: '*'
          destinationPortRange: '22'
          sourceAddressPrefix: allowIpPort22
          destinationAddressPrefix: '*'
          access: 'Allow'
          priority: 100
          direction: 'Inbound'
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
    ]
  }
}

resource loadBalancer 'Microsoft.Network/loadBalancers@2020-05-01' = {
  name: loadBalancerName
  location: location
  sku: {
    name: 'Standard'
  }
  properties: {
    frontendIPConfigurations: [
      {
        name: 'LoadBalancerFrontEnd'
        properties: {
          publicIPAddress: {
            id: publicIPAddressID
          }
        }
      }
    ]
    backendAddressPools: [
      {
        name: bePoolName
      }
    ]
    inboundNatPools: [
      {
        name: natPoolName
        properties: {
          frontendIPConfiguration: {
            id: frontEndIPConfigID
          }
          protocol: 'Tcp'
          frontendPortRangeStart: natStartPort
          frontendPortRangeEnd: natEndPort
          backendPort: natBackendPort
        }
      }
    ]
    loadBalancingRules: [
      {
        name: 'Rule_80'
        properties: {
          loadDistribution: 'Default'
          frontendIPConfiguration: {
            id: frontEndIPConfigID
          }
          backendAddressPool: {
            id: '/subscriptions/${subscription().subscriptionId}/resourceGroups/${resourceGroup().name}/providers/Microsoft.Network/loadBalancers/${loadBalancerName}/backendAddressPools/${bePoolName}'
          }
          protocol: 'Tcp'
          frontendPort: 80
          backendPort: 80
          enableFloatingIP: false
          idleTimeoutInMinutes: 5
          probe: {
            id: resourceId('Microsoft.Network/loadBalancers/probes', loadBalancerName, 'Probe_80')
          }
        }
      }
      {
        name: 'Rule_443'
        properties: {
          loadDistribution: 'Default'
          frontendIPConfiguration: {
            id: frontEndIPConfigID
          }
          backendAddressPool: {
            id: '/subscriptions/${subscription().subscriptionId}/resourceGroups/${resourceGroup().name}/providers/Microsoft.Network/loadBalancers/${loadBalancerName}/backendAddressPools/${bePoolName}'
          }
          protocol: 'Tcp'
          frontendPort: 443
          backendPort: 443
          enableFloatingIP: false
          idleTimeoutInMinutes: 5
          probe: {
            id: resourceId('Microsoft.Network/loadBalancers/probes', loadBalancerName, 'Probe_443')
          }
        }
      }
    ]
    probes: [
      {
        name: 'Probe_80'
        properties: {
          protocol: 'Tcp'
          port: 80
          intervalInSeconds: 5
          numberOfProbes: 2
        }
      }
      {
        name: 'Probe_443'
        properties: {
          protocol: 'Tcp'
          port: 443
          intervalInSeconds: 5
          numberOfProbes: 2
        }
      }
    ]
  }
}

resource vmssName_resource 'Microsoft.Compute/virtualMachineScaleSets@2019-12-01' = {
  name: vmssName_var
  location: location
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: {
      '${identityName.id}': {}
    }
  }
  sku: {
    name: vmSize
    capacity: instanceCount
    tier: vmssTier
  }
  properties: {
    overprovision: true
    upgradePolicy: {
      mode: 'Manual'
    }
    virtualMachineProfile: {
      priority: vmssPriority
      evictionPolicy: ((vmssPriority == 'Regular') ? json('null') : vmssEvictionPolicy)
      storageProfile: {
        osDisk: {
          managedDisk: {
            storageAccountType: diskAccountType
          }
          diskSizeGB: osDiskSize
          createOption: 'FromImage'
          caching: 'ReadWrite'
        }
        imageReference: {
          publisher: imagePublisher
          offer: imageOffer
          sku: imageSku
          version: 'latest'
        }
      }
      osProfile: {
        computerNamePrefix: vmssName_var
        customData: ((customDataUrl == '') ? json('null') : customDataAdvanced)
        adminUsername: adminUsername
        linuxConfiguration: {
          disablePasswordAuthentication: true
          ssh: {
            publicKeys: [
              {
                keyData: adminPasswordOrKey
                path: '/home/${adminUsername}/.ssh/authorized_keys'
              }
            ]
          }
        }
      }
      networkProfile: {
        networkInterfaceConfigurations: [
          {
            name: nicName
            properties: {
              primary: true
              ipConfigurations: [
                {
                  name: ipConfigName
                  properties: {
                    subnet: {
                      id: '/subscriptions/${subscription().subscriptionId}/resourceGroups/${resourceGroup().name}/providers/Microsoft.Network/virtualNetworks/${virtualNetworkName_var}/subnets/${subnetName}'
                    }
                    loadBalancerBackendAddressPools: [
                      {
                        id: '/subscriptions/${subscription().subscriptionId}/resourceGroups/${resourceGroup().name}/providers/Microsoft.Network/loadBalancers/${loadBalancerName}/backendAddressPools/${bePoolName}'
                      }
                    ]
                    loadBalancerInboundNatPools: [
                      {
                        id: '/subscriptions/${subscription().subscriptionId}/resourceGroups/${resourceGroup().name}/providers/Microsoft.Network/loadBalancers/${loadBalancerName}/inboundNatPools/${natPoolName}'
                      }
                    ]
                  }
                }
              ]
            }
          }
        ]
      }
    }
  }
  dependsOn: [
    loadBalancer
    virtualNetworkName
  ]
}

output fqdn string = publicIPAddressName.properties.dnsSettings.fqdn
