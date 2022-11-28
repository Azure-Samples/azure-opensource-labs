# Mastodon on Azure with Linux & Docker Compose

## Azure Portal

Use the following link to deploy the template in this repo using the Azure Portal:

[![Deploy to Azure](https://aka.ms/deploytoazurebutton)](https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2FAzure-Samples%2Fazure-opensource-labs%2Flinux-mastodon-1%2Flinux%2Fvm-mastodon%2Fvm.json)

If you would like to deploy the Bicep template via the Azure CLI, explore the **Azure CLI** section below. To update the Deploy to Azure button with your own template, explore the **Azure Portal (continued)** section below. Otherwise, continue to **Get Credentials**.

## Get Credentials

### Tailscale

If you are using Tailscale, you can simply run this at the command line.

```bash
ssh azureuser@web1 'cat ~/admin.txt'
```

### Azure Portal

If you are using the Azure Portal, take the following steps:

1. Open <https://portal.azure.com>
2. Find the resource group where your VM is located.
3. Click on the VM.
4. Find `Operations > Run command` on the left hand side.
5. Click `RunShellScript`.
6. Type `cat /home/azureuser/admin.txt`.
7. Click `Run` and wait for the output.

## Azure CLI

```bash
cd linux/vm-mastodon/

RESOURCE_GROUP='221100-vm-mastodon'
LOCATION='eastus'

az group create \
    --name $RESOURCE_GROUP \
    --location $LOCATION

# vm.bicep
az deployment group create \
    --resource-group $RESOURCE_GROUP \
    --template-file vm.bicep

# vm-test.bicep - defaults
az deployment group create \
    --resource-group $RESOURCE_GROUP \
    --template-file vm-test.bicep

# vm-test.bicep - parameters
az deployment group create \
    --resource-group $RESOURCE_GROUP \
    --template-file vm.bicep \
    --parameters \
        tsKey='tskey-auth-kkZtj55CNTRL-nWm4KrGLr9Bfda4KrGLr9BPDdXxWmu75K' \
        siteAddress='' \
        letsEncryptEmail='aaron.w@on365.org'

# empty resource group
az deployment group create \
    --resource-group $RESOURCE_GROUP \
    --template-file empty.json \
    --mode Complete
```

## Azure Portal (continued)

```bash
# create vm.json
az bicep build -f vm.bicep

# create url
#BRANCH_OR_COMMIT='linux-mastodon-1'
BRANCH_OR_COMMIT=$(git rev-parse HEAD)
TEMPLATE_URL="https://raw.githubusercontent.com/Azure-Samples/azure-opensource-labs/${BRANCH_OR_COMMIT}/linux/vm-mastodon/vm.json"
OUTPUT_URL='https://portal.azure.com/#create/Microsoft.Template/uri/'$(printf "$TEMPLATE_URL" | jq -s -R -r @uri )
echo $OUTPUT_URL

# https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2FAzure-Samples%2Fazure-opensource-labs%2Flinux-mastodon-1%2Flinux%2Fvm-mastodon%2Fvm.json
```
