# NOTES

## cli

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

## portal

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
