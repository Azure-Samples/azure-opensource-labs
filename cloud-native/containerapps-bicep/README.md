# README

```bash
RESOURCE_GROUP="my-container-apps"
LOCATION="canadacentral"
CONTAINERAPPS_ENVIRONMENT="my-environment"
STORAGE_ACCOUNT_CONTAINER="mycontainer"

az group create \
  --name $RESOURCE_GROUP \
  --location "$LOCATION"

STORAGE_ACCOUNT="storage220500"

az storage account create \
  --name $STORAGE_ACCOUNT \
  --resource-group $RESOURCE_GROUP \
  --location "$LOCATION" \
  --sku Standard_RAGRS \
  --kind StorageV2

az deployment group create \
  --resource-group "$RESOURCE_GROUP" \
  --template-file ./hello-world.bicep \
  --parameters \
      environment_name="$CONTAINERAPPS_ENVIRONMENT" \
      location="$LOCATION" \
      storage_account_name="$STORAGE_ACCOUNT" \
      storage_container_name="$STORAGE_ACCOUNT_CONTAINER"
```
