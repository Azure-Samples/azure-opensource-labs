# Deploy Azure Kubernetes Service (AKS) with Bicep and Azure Verified Modules (AVM)

Deploys [Azure Kubernetes Service (AKS)](https://learn.microsoft.com/azure/aks/what-is-aks) running [Azure Linux](https://learn.microsoft.com/azure/aks/use-azure-linux) and [Azure Cobalt 100 Arm-based VMs](https://learn.microsoft.com/azure/virtual-machines/sizes/cobalt-overview).

## Deploy via Azure Portal

[Deploy to Azure](https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2FAzure-Samples%2Fazure-opensource-labs%2Fmain%2Fcloud-native%2Faks-arm%2Faks.json)

## Prerequisites

- Azure Subscription
- Azure CLI
- Bicep

## Setup

Azure Linux V3 Preview feature registration:

```bash
az feature register \
    --namespace Microsoft.ContainerService \
    --name AzureLinuxV3Preview
```

```bash
az feature show \
    --namespace Microsoft.ContainerService \
    --name AzureLinuxV3Preview
```

```bash
az provider register \
    -n Microsoft.ContainerService
```

## Deploy via Azure CLI

Set environment variables:

```bash
export RESOURCE_GROUP='250400-aks'
export LOCATION='eastus'
```

Create resource group:

```bash
az group create \
    --name $RESOURCE_GROUP \
    --location $LOCATION
```

Deploy Azure Kubernetes Service (AKS) cluster:

```bash
az deployment group create \
    --resource-group $RESOURCE_GROUP \
    --template-file aks.bicep
```

Deploy Azure Kubernetes Service (AKS) cluster with Role Assignment:

```bash
ASSIGNEE=$(az ad signed-in-user show --query id -o tsv)

az deployment group create \
    --resource-group $RESOURCE_GROUP \
    --template-file aks.bicep \
    --mode Complete \
    --parameters userPrincipalId=${ASSIGNEE} \
    --parameters additionalParam=value
    
Monitor the deployment in the Azure Portal:

```bash
AZ_ACCOUNT=$(az account show)
TENANT_DOMAIN=$(echo $AZ_ACCOUNT | jq -r '.tenantDefaultDomain')
SUBSCRIPTION_ID=$(echo $AZ_ACCOUNT | jq -r '.id')

echo "Open in Azure Portal:"
echo "https://portal.azure.com/#@${TENANT_DOMAIN}/resource/subscriptions/${SUBSCRIPTION_ID}/resourceGroups/${RESOURCE_GROUP}/deployments"
```

## Connect to AKS Cluster

```bash
az aks get-credentials \
    --resource-group $RESOURCE_GROUP \
    --name aks-1
```

Check connection the cluster:

```bash
kubectl get nodes
```

Check connection to the cluster with verbose output:

```bash
kubectl get nodes -v=10
```

Assign correct role (if needed):

```bash
ASSIGNEE=$(az ad signed-in-user show --query id -o tsv)
SUBSCRIPTION_ID=$(az account show --query id -o tsv)
AKS_NAME='aks-1'

az role assignment create \
  --assignee ${ASSIGNEE} \
  --role "Azure Kubernetes Service RBAC Cluster Admin" \
  --scope "/subscriptions/${SUBSCRIPTION_ID}/resourceGroups/${RESOURCE_GROUP}/providers/Microsoft.ContainerService/managedClusters/${AKS_NAME}"
```

## Cleanup

Deploy the empty Bicep template:

```bash
az deployment group create \
    --resource-group $RESOURCE_GROUP \
    --mode Complete \
    --template-file empty.bicep
```

Delete resource group:

```bash
az group delete \
    --name $RESOURCE_GROUP \
    --yes
```

Confirm resource group deleted:

```bash
az group show \
    --name $RESOURCE_GROUP
```
