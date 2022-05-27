# README

```bash
RESOURCE_GROUP="my-container-apps"
LOCATION="canadacentral"

az group create \
  --name $RESOURCE_GROUP \
  --location "$LOCATION"

# containerapp
az deployment group create \
  --resource-group "$RESOURCE_GROUP" \
  --template-file ./containerapp.bicep \
  --parameters \
      location="$LOCATION"

# storage
az deployment group create \
  --resource-group "$RESOURCE_GROUP" \
  --template-file ./storage.bicep

# postgres + keyvault
az deployment group create \
  --resource-group "$RESOURCE_GROUP" \
  --template-file ./postgres-keyvault.bicep

# key vault
az deployment group create \
  --resource-group "$RESOURCE_GROUP" \
  --template-file ./keyvault.bicep

# postgres
az deployment group create \
  --resource-group "$RESOURCE_GROUP" \
  --template-file ./postgres.bicep

# empty
az deployment group create \
  --mode Complete \
  --resource-group "$RESOURCE_GROUP" \
  --template-file ./empty.bicep
```
