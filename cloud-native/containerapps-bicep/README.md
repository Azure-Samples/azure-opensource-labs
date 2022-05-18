# README

```bash
RESOURCE_GROUP="my-container-apps"
LOCATION="canadacentral"

az group create \
  --name $RESOURCE_GROUP \
  --location "$LOCATION"

az deployment group create \
  --resource-group "$RESOURCE_GROUP" \
  --template-file ./hello-world.bicep \
  --parameters \
      location="$LOCATION"
      env_name="$CONTAINERAPPS_ENVIRONMENT"
```
