# azure-virtual-network

This module deploys a [Microsoft.Network/virtualNetworks](https://learn.microsoft.com/azure/templates/microsoft.network/virtualnetworks?pivots=deployment-language-bicep) resource with a single [Microsoft.Network/virtualNetworks/subnets](https://learn.microsoft.com/azure/templates/microsoft.network/virtualnetworks/subnets?pivots=deployment-language-bicep) resource using only parameters scoped for these labs.

## Inputs

| Name | Description | Expected Value |
|------|-------------|----------------|
| `name` | This is the name of the resource | Whatever you want |
| `location` | Region to deploy resource into | Azure region that offers this resource |
| `tags` | Tags | Object of key/value pairs |
| `vnetAddressPrefix` | Network CIDR range | Ex: 10.21.0.0/16 |
| `snetAddressPrefix` | Subnet CIDR range | Ex: 10.21.0.0/24 |
| `snetName` | Name of the subnet | Whatever you want |
| `networkSecurityGroupId` | Resource ID of the network security group. This will be associated to the subnet | Resource ID |
| `dnsServer` | Optionally, set a DNS server IP or leave empty to use Azure DNS | IP address or empty string |

## Outputs

| Name | Description |
|------|-------------|
| `id` | This is the id of the virtual network resource |
| `name` | This is the name of the virtual network resource |
| `subnetId` | This is the id of the subnet resource |
