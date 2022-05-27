# POSTGRES

```bash
RESOURCE_GROUP='my-container-apps'

POSTGRES_NAME=$(az postgres flexible-server list \
    --resource-group $RESOURCE_GROUP \
    --out tsv \
    --query '[0].name')

CLIENT_IP=$(dig @1.1.1.1 ch txt whoami.cloudflare +short | tr -d '"')

az postgres flexible-server firewall-rule create \
    --resource-group $RESOURCE_GROUP \
    --name $POSTGRES_NAME \
    --rule-name 'AllowLocalIP' \
    --start-ip-address $CLIENT_IP \
    --end-ip-address $CLIENT_IP

KEYVAULT_NAME=$(az keyvault list \
    --resource-group $RESOURCE_GROUP \
    --out tsv \
    --query '[0].name')

export PGPASSWORD=$(az keyvault secret show \
    --vault-name $KEYVAULT_NAME \
    --name "${POSTGRES_NAME}-password" \
    --out tsv \
    --query value)

psql "postgres://username:${PGPASSWORD}@${POSTGRES_NAME}.postgres.database.azure.com/postgres?sslmode=require"
```
