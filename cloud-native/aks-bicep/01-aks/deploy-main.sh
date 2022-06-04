[[ -z "${RESOURCE_GROUP:-}" ]] && RESOURCE_GROUP='220600-keda'
[[ -z "${LOCATION:-}" ]] && LOCATION='eastus'
[[ -z "${AKS_NAME:-}" ]] && AKS_NAME='aks1'

az deployment sub create \
    --location $LOCATION \
    --template-file ./main.bicep \
    --parameters \
        deployScript='true' \
        scriptUri='https://raw.githubusercontent.com/Azure-Samples/azure-opensource-labs/aks-bicep/cloud-native/aks-bicep/01-aks/deploy-script-keda.sh' \
        resourceGroup=$RESOURCE_GROUP
