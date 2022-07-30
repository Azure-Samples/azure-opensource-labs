# Linux on Azure with Bicep/ARM and Virtual Machines (VM)

## Azure Portal

[Deploy to Azure](https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2FAzure-Samples%2Fazure-opensource-labs%2Fmain%2Flinux%2Fvm%2Fvm.json)

## Resource Group 

```bash
RESOURCE_GROUP='220700-azure-linux'
LOCATION='eastus'
az group create \
    --name $RESOURCE_GROUP \
    --location $LOCATION
```

## Virtual Machine (VM)

```bash
# environment variables
RESOURCE_GROUP='220700-azure-linux'

# basic
az deployment group create \
    --resource-group $RESOURCE_GROUP \
    --template-file vm.bicep

# advanced - ssh key, allowed ip
PASSWORD_OR_KEY="$(cat ~/.ssh/id_rsa.pub)"
IP_ALLOW=$(dig @1.1.1.1 ch txt whoami.cloudflare +short | tr -d '"')

OUTPUT=$(az deployment group create \
    --resource-group $RESOURCE_GROUP \
    --template-file vm.bicep \
    --parameters \
        adminPasswordOrKey="$PASSWORD_OR_KEY" \
        allowIpPort22="$IP_ALLOW")

# advanced - named vm, cloud-init, env.json
VM_NAME='vm2'
ENV=$(cat _/env.json)
OUTPUT=$(az deployment group create \
    --resource-group $RESOURCE_GROUP \
    --template-file vm.bicep \
    --parameters \
        vmName="$VM_NAME" \
        cloudInit='vpn' \
        env="$ENV")

echo $OUTPUT | jq -r '.properties.outputs.sshCommand.value'
```

# Delete Resources

```bash
# empty resource group
az deployment group create \
    --resource-group $RESOURCE_GROUP \
    --template-file empty.json \
    --mode Complete

# alternatively, delete single vm and disk for re-deployment
VM_NAME='vm2'
az vm delete --yes --resource-group $RESOURCE_GROUP --name $VM_NAME 
az disk delete --yes --resource-group $RESOURCE_GROUP --name "${VM_NAME}-osdisk1"
```
