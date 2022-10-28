# azure-kubernetes-service

This module deploys a [Microsoft.ContainerService/managedClusters](https://learn.microsoft.com/azure/templates/microsoft.containerservice/managedclusters?pivots=deployment-language-bicep) resource using only parameters scoped for these labs.

## Inputs

| Name | Description | Expected Value |
|------|-------------|----------------|
| `name` | This is the name of the resource | Whatever you want |
| `location` | Region to deploy resource into | Azure region that offers this resource |
| `tags` | Tags | Object of key/value pairs |
| `slaTier` | Defaults to Free tier | `'Free'` <br/> 'Paid' |
| `managedIdentityType` | Two options are available: SystemAssigned or UserAssigned | `'SystemAssigned'` <br/> `'UserAssigned'` |
| `userAssignedIdentities` | Required when managed identity type is set to UserAssigned | |
| `kubernetesVersion` | Default is `1.24.3` | `'1.24.3'` |
| `defenderEnabled` | Enables Defender on AKS cluster | `true` or `false` |
| `imageCleanerEnabled` | Enables ImageCleaner on AKS cluster. | `true` or `false` |
| `imageCleanerIntervalHours` | ImageCleaner scanning interval in hours | Number |
| `systemNodeCount` | Number of nodes to deploy in the system node pool | Number |
| `systemNodeVmSize` | Default system node pool size is `Standard_D2s_v5` | A valid SKU available in your chosen Azure region |
| `registryName` | Optional parameter to attach AKS cluster to an existing ACR | Name of your registry (you can omit the `azurecr.io` suffix) |
| `networkPlugin` | Network plugin used for building the Kubernetes network. | `'kubenet'` <br/> `'azure'` <br/> `'none'` |
| `networkPolicy` | Network policy used for building the Kubernetes network. | `'calico'` <br/> `'azure'` |
| `loadBalancerSku` | The default is standard | `'Standard'` <br/> `'Basic'` |
| `dnsServiceIP` | An IP address assigned to the Kubernetes DNS service. It must be within the Kubernetes service address range specified in serviceCidr. | `'10.0.0.10'` |
| `dockerBridgeCidr` | A CIDR notation IP range assigned to the Docker bridge network. It must not overlap with any Subnet IP ranges or the Kubernetes service address range. | `'172.17.0.1/16'` |
| `outboundType` | This can only be set at cluster creation time and cannot be changed later. | `'loadBalancer'` <br/> `'managedNATGateway'` <br/> `'userAssignedNATGateway'` <br/> `'userDefinedRouting'` |
| `podCidrs` | One IPv4 CIDR is expected for single-stack networking. Two CIDRs, one for each IP family (IPv4/IPv6), is expected for dual-stack networking. | `'10.244.0.0/16'` |
| `serviceCidrs` | One IPv4 CIDR is expected for single-stack networking. Two CIDRs, one for each IP family (IPv4/IPv6), is expected for dual-stack networking. They must not overlap with any Subnet IP ranges. | `'10.0.0.0/16'` |
| `ipFamilies` | |  `'IPv4'` <br/>  `'IPv6'` |
| `vnetSubnetID` | Id of the Vnet to deploy cluster into | |
| `nodeTaints` | Enable nodeTaints on the system node pool (e.g., [\'CriticalAddonsOnly=true:NoSchedule\']) | |
| `addonProfiles` | Add-ons to enable | Object? 🤔 No concrete definition so your best best is to deploy using Azure CLI or Portal and see what the JSON metadata looks like |

## Outputs

| Name | Description |
|------|-------------|
| `name` | This is the name of the AKS resource |
