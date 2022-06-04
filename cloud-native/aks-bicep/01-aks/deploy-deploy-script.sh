[[ -z "${RESOURCE_GROUP:-}" ]] && RESOURCE_GROUP='220600-keda'
[[ -z "${LOCATION:-}" ]] && LOCATION='eastus'

az deployment group create \
    --resource-group $RESOURCE_GROUP \
    --mode incremental \
    --template-file ./deploy-script.bicep \
    --parameters \
        scriptUri='https://raw.githubusercontent.com/Azure-Samples/azure-opensource-labs/aks-bicep/cloud-native/aks-bicep/01-aks/deploy-script-aks.sh'
