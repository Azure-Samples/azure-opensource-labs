# Cloud Native Python with Azure Container Apps, Container Registry, and FastAPI on PyPy

## 1. clone sample

```bash
git clone https://github.com/tonybaloney/ants-azure-demos.git

cd ants-azure-demos/pypy-fastapi-container-instance/
```

## 2. set environment variables

```bash
RESOURCE_GROUP="my-container-apps"
LOCATION="canadacentral"
CONTAINERAPPS_ENVIRONMENT="my-environment"

SUBSCRIPTION_ID=$(az account show --query id --out tsv)
SCOPE="/subscriptions/${SUBSCRIPTION_ID}/resourceGroups/${RESOURCE_GROUP}"
[[ -z "${RANDOM_STR:-}" ]] && RANDOM_STR=$(echo -n "$SCOPE" | shasum | head -c 6)

ACR_NAME="acr${RANDOM_STR}"
ACR_IMAGE_NAME="pypy-fastapi:latest"
```

## 3. create resource group

```bash
az group create \
  --name $RESOURCE_GROUP \
  --location $LOCATION
```

## 4. create azure container registry

[Quickstart](https://docs.microsoft.com/en-us/azure/container-registry/container-registry-get-started-azure-cli)

```bash
az acr create --resource-group $RESOURCE_GROUP \
  --name $ACR_NAME \
  --sku Basic \
  --admin-enabled true

az acr build -t $ACR_IMAGE_NAME -r $ACR_NAME .

CONTAINER_IMAGE="${ACR_NAME}.azurecr.io/${ACR_IMAGE_NAME}"
REGISTRY_SERVER="${ACR_NAME}.azurecr.io"
REGISTRY_USERNAME="${ACR_NAME}"
REGISTRY_PASSWORD=$(az acr credential show -n $ACR_NAME --query 'passwords[0].value' --out tsv)

echo "$CONTAINER_IMAGE"
```

## 5. create azure container apps environment

[Quickstart](https://docs.microsoft.com/en-us/azure/container-apps/get-started-existing-container-image?tabs=bash&pivots=container-apps-private-registry)

```bash
az extension add --name containerapp

az containerapp env create \
  --name $CONTAINERAPPS_ENVIRONMENT \
  --resource-group $RESOURCE_GROUP \
  --location $LOCATION
```

## 6. create container app

```bash
az containerapp create \
  --name my-container-app \
  --resource-group $RESOURCE_GROUP \
  --environment $CONTAINERAPPS_ENVIRONMENT \
  --image "$CONTAINER_IMAGE" \
  --registry-server "$REGISTRY_SERVER" \
  --registry-username "$REGISTRY_USERNAME" \
  --registry-password "$REGISTRY_PASSWORD" \
  --target-port 80 \
  --ingress 'external'
```

## 7. test app with curl

```bash
CONTAINERAPP_FQDN=$(az containerapp show --resource-group $RESOURCE_GROUP \
  --name my-container-app \
  --query properties.configuration.ingress.fqdn \
  --out tsv)

echo "https://${CONTAINERAPP_FQDN}"

curl "https://${CONTAINERAPP_FQDN}/locations"
```

## 8. delete resource group

```bash
az group delete \
  --name $RESOURCE_GROUP
```
