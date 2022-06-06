[[ -z "${RESOURCE_GROUP:-}" ]] && RESOURCE_GROUP='220600-keda'

az deployment group create \
    --resource-group $RESOURCE_GROUP \
    --mode incremental \
    --template-file ./keyvault.bicep 
