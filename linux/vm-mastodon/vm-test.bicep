@description('The name of your Virtual Machine.')
param vmName string = 'web1'

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
  'Ubuntu 20.04-LTS'
  'Ubuntu 20.04-LTS (arm64)'
  'Ubuntu 18.04-LTS'
])
param osImage string = 'Ubuntu 20.04-LTS'

@description('Location for all resources.')
param location string = resourceGroup().location

@description('Name of the VNET.')
param virtualNetworkName string = ''

@description('Default IP to allow Port 22 (SSH). Set to your own IP Address')
param allowIpPort22 string = '127.0.0.1'

@description('Username for the Virtual Machine.')
param adminUsername string = 'azureuser'

@secure()
@description('SSH Key for the Virtual Machine.')
param adminPasswordOrKey string = ''

@description('Deploy with cloud-init.')
@allowed([
  'none'
  'tailscale-mastodon'
])
param cloudInit string = 'tailscale-mastodon'

//@description('Environment variables as JSON object.')
//@secure()
//param env object = {}

@secure()
@description('Tailscale Auth Key')
param tsKey string = ''

@description('Lets Encrypt Email')
param letsEncryptEmail string = ''

@description('Site Address')
param siteAddress string = ''

var siteAddress_var = siteAddress != '' ? siteAddress : toLower('${vmName}-${rand}.${location}.cloudapp.azure.com')

var env = {
  tskey: tsKey
  letsEncryptEmail: letsEncryptEmail
  siteAddress: siteAddress_var
}

var rand = substring(uniqueString(resourceGroup().id), 0, 6)
var virtualNetworkName_var = virtualNetworkName != '' ? virtualNetworkName : '${resourceGroup().name}-vnet'
var subnetName = 'default'
var keyData_var = adminPasswordOrKey != '' ? adminPasswordOrKey : 'ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQC3gkRpKwprN00sT7yekr0xO0F+uTllDua02puhu1v0zGu3aENvUsygBHJiTy+flgrO2q3mY9F5/D67+WHDeSpr5s71UtnbzMxTams89qmo+raTm+IqjzdNujaWf0/pbT6JUkQq0fR0BfIvg3/7NTXhlzjmCOP2EpD91LzN6b5jAm/5hXr0V5mcpERo8kk2GWxjKmwmDOV+huH1DIFDpMxT3WzR2qvZp1DZbNSYmKkrite3FHlPGLXA1I3bRQT+iTj8vRGpxOPSiMdPK4RNMEZVXSGQ3OZbSl2FBCbd/tdJ1idKo8/ZCkHxdh9/em28/yfPUK0D164shgiEdIkdOQJv'
var publicIPAddressName = '${vmName}-ip'
var networkInterfaceName = '${vmName}-nic'
var ipConfigName = '${vmName}-ipconfig'
var subnetAddressPrefix = '10.1.0.0/24'
var addressPrefix = '10.1.0.0/16'

var cloudInitTailscaleMastodon = '''
#cloud-config
# vim: syntax=yaml

packages:
- docker.io
- docker-compose
- jq
- make

# create the docker group
groups:
- docker

# Add default auto created user to docker group
system_info:
  default_user:
    groups: [docker]

write_files:

- path: /home/azureuser/env.json
  content: {0}
  encoding: b64

- path: /home/azureuser/tailscale.sh
  content: |
    curl -fsSL https://pkgs.tailscale.com/stable/ubuntu/focal.noarmor.gpg | sudo tee /usr/share/keyrings/tailscale-archive-keyring.gpg >/dev/null
    curl -fsSL https://pkgs.tailscale.com/stable/ubuntu/focal.tailscale-keyring.list | sudo tee /etc/apt/sources.list.d/tailscale.list
    
    sudo apt-get update
    sudo apt-get install -y tailscale
    
    sudo tailscale up --advertise-routes=10.1.0.0/24,168.63.129.16/32 --accept-dns=false --ssh --authkey "$1"

- path: /home/azureuser/mastodon.sh
  content: |
    cd $HOME
    git clone https://github.com/asw101/tmp -b fractured-monkey-1
    cd tmp
    
    export SITE_ADDRESS=$(jq -r '.siteAddress' env.json)
    export LETS_ENCRYPT_EMAIL=$(jq -r '.letsEncryptEmail' env.json)
    export TLS_INTERNAL=''
    
    make run-postgres
    make config
    sudo make setup-db
    make setup-admin > ../admin.txt
    make run

runcmd:
- cd /home/azureuser/
- bash tailscale.sh "$(jq -r '.tskey' env.json)"
- echo $(date) > hello.txt
- chown -R azureuser:azureuser /home/azureuser/
'''

var cloudInitTailscaleMastodonFormat = format(cloudInitTailscaleMastodon, base64(string(env)))

var kvCloudInit = {
  none: json('null')
  'tailscale-mastodon': base64(cloudInitTailscaleMastodonFormat)
}

// ---
output adminUsername string = adminUsername
output hostname string = vmName
output cloudInitTailscaleMastodonFormat string = cloudInitTailscaleMastodonFormat
