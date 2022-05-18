# README

```bash
RESOURCE_GROUP="my-containerapps"
LOCATION="canadacentral"
CONTAINERAPPS_ENVIRONMENT="containerapps-env"
STORAGE_ACCOUNT_CONTAINER="mycontainer"

az group create \
  --name $RESOURCE_GROUP \
  --location "$LOCATION"

az deployment group create \
  --resource-group "$RESOURCE_GROUP" \
  --template-file ./hello-world.bicep \
  --parameters \
      environment_name="$CONTAINERAPPS_ENVIRONMENT" \
      location="$LOCATION" \
      storage_account_name="$STORAGE_ACCOUNT" \
      storage_container_name="$STORAGE_ACCOUNT_CONTAINER"
```
