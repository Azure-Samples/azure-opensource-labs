# Serverless Containers with Go, Azure Container Apps, and GitHub Container Registry

## 1. build and containerize asw101/go-hello

[Walkthrough (vimeo.com)](https://vimeo.com/696758621/eb0fc146b4)

1. Visit <https://github.com/asw101/go-hello>
1. Click "Use this template".
1. Name your repo "serverless-gopher".
1. Create a new branch called release.
1. Click on the Actions tab.
1. View the output of the action.
1. Return to the main repo (Code tab).
1. Click on "serverless-gopher" under "Packages" on the right hand size.
1. Copy the `docker pull` command which will include the image name.
1. Update the `GITHUB_USER_OR_ORG` environment variable below with your GitHub username or organization name.

## 2. set environment variables

```bash
RESOURCE_GROUP="my-container-apps"
LOCATION="canadacentral"
CONTAINERAPPS_ENVIRONMENT="my-environment"

GITHUB_USER_OR_ORG="asw101"
CONTAINER_IMAGE="ghcr.io/${GITHUB_USER_OR_ORG}/serverless-gopher:release"
```

## 3. create resource group

```bash
az group create \
  --name $RESOURCE_GROUP \
  --location $LOCATION
```

## 4. create azure container apps environment

[Quickstart](https://docs.microsoft.com/en-us/azure/container-apps/get-started-existing-container-image?tabs=bash&pivots=container-apps-private-registry)

```bash
az extension add --name containerapp

az containerapp env create \
  --name $CONTAINERAPPS_ENVIRONMENT \
  --resource-group $RESOURCE_GROUP \
  --location $LOCATION
```

## 5. create container app with a public image

```bash
az containerapp create \
  --name my-container-app \
  --resource-group $RESOURCE_GROUP \
  --environment $CONTAINERAPPS_ENVIRONMENT \
  --image "$CONTAINER_IMAGE" \
  --target-port 80 \
  --ingress 'external'
```

## 6. test app with curl

```bash
CONTAINERAPP_FQDN=$(az containerapp show --resource-group $RESOURCE_GROUP \
  --name my-container-app \
  --query properties.configuration.ingress.fqdn \
  --out tsv)

echo "https://${CONTAINERAPP_FQDN}"

curl "https://${CONTAINERAPP_FQDN}"
```

## 7. delete resource group

```bash
az group delete \
  --name $RESOURCE_GROUP
```
