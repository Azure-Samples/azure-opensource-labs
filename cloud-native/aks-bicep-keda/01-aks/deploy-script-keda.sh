[[ -z "${RESOURCE_GROUP:-}" ]] && RESOURCE_GROUP='220600-keda'
[[ -z "${AKS_NAME:-}" ]] && AKS_NAME='aks1'

echo "az aks command invoke"
az aks command invoke \
    --resource-group $RESOURCE_GROUP \
    --name $AKS_NAME \
    --command 'kubectl apply -f https://github.com/kedacore/keda/releases/download/v2.7.1/keda-2.7.1.yaml'
