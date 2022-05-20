# Linux on Azure with ARM and Virtual Machine Scale Sets (VMSS)

## Resource Group 

```bash
RESOURCE_GROUP='220500-azure-linux'
LOCATION='eastus'
az group create -n $RESOURCE_GROUP -l $LOCATION
```

## VMSS 

```bash
RESOURCE_GROUP='220500-azure-linux'
PASSWORD_OR_KEY="$(cat ~/.ssh/id_rsa.pub)"

az deployment group create --resource-group $RESOURCE_GROUP --template-file azuredeploy.json \
    --parameters adminPasswordOrKey="$PASSWORD_OR_KEY"

az deployment group create --resource-group $RESOURCE_GROUP --template-file azuredeploy.json \
    --parameters adminPasswordOrKey="$PASSWORD_OR_KEY" \
        vmName=vm2 \
        customDataUrl='https://raw.githubusercontent.com/Azure-Samples/azure-opensource-labs/linux-vmss/linux/vmss/cloud-init/cloud-init.sh'
```

## Portal 

[Deploy to Azure](https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2FAzure-Samples%2Fazure-opensource-labs%2Flinux-vmss%2Flinux%2Fvmss%2Fazuredeploy.json)

```bash
TEMPLATE_URL='https://raw.githubusercontent.com/Azure-Samples/azure-opensource-labs/linux-vmss/linux/vmss/azuredeploy.json'
OUTPUT_URL='https://portal.azure.com/#create/Microsoft.Template/uri/'$(printf "$TEMPLATE_URL" | jq -s -R -r @uri )
echo $OUTPUT_URL

# https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2FAzure-Samples%2Fazure-opensource-labs%2Flinux-vmss%2Flinux%2Fvmss%2Fazuredeploy.json
```
