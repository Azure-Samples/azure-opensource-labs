# Linux on Azure with Bicep/ARM and Virtual Machine Scale Sets (VMSS)

## Resource Group 

```bash
RESOURCE_GROUP='220500-azure-linux'
LOCATION='eastus'
az group create \
    --name $RESOURCE_GROUP \
    --location $LOCATION
```

## Virtual Machine Scale Set (VMSS)

```bash
RESOURCE_GROUP='220500-azure-linux'
PASSWORD_OR_KEY="$(cat ~/.ssh/id_rsa.pub)"

az deployment group create \
    --resource-group $RESOURCE_GROUP \
    --template-file vmss.bicep \
    --parameters adminPasswordOrKey="$PASSWORD_OR_KEY"

az deployment group create \
    --resource-group $RESOURCE_GROUP \
    --template-file vmss.bicep \
    --parameters adminPasswordOrKey="$PASSWORD_OR_KEY" \
        vmName=vm2 \
        customDataUrl='https://raw.githubusercontent.com/Azure-Samples/azure-opensource-labs/main/linux/vmss/cloud-init/cloud-init.sh'

# deploy with ALLOW_IP
IP_ALLOW=$(dig @1.1.1.1 ch txt whoami.cloudflare +short | tr -d '"')

az deployment group create \
    --resource-group $RESOURCE_GROUP \
    --template-file vmss.bicep \
    --parameters adminPasswordOrKey="$PASSWORD_OR_KEY" \
    allowIpPort22="$IP_ALLOW"
```

## Portal 

[Deploy to Azure](https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2FAzure-Samples%2Fazure-opensource-labs%2Fmain%2Flinux%2Fvmss%2Fvmss.json)

```bash
TEMPLATE_URL='https://raw.githubusercontent.com/Azure-Samples/azure-opensource-labs/main/linux/vmss/vmss.json'
OUTPUT_URL='https://portal.azure.com/#create/Microsoft.Template/uri/'$(printf "$TEMPLATE_URL" | jq -s -R -r @uri )
echo $OUTPUT_URL

# https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2FAzure-Samples%2Fazure-opensource-labs%2Fmain%2Flinux%2Fvmss%2Fvmss.json
```
