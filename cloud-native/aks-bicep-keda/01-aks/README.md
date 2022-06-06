# 01-aks/

This folder contains bicep templates and scripts to deploy Azure Kubernetes Service (AKS), Managed Identity, Container Registry and related resources.  

## Build ARM (main.json) from Bicep

```bash
az bicep build --file main.bicep --outfile main.json
```

## Deploy ARM (main.json) via Azure Portal

[Deploy to Azure](https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2FAzure-Samples%2Fazure-opensource-labs%2Fmain%2Fcloud-native%2Faks-bicep-keda%2F01-aks%2Fmain.json)

```bash
TEMPLATE_URL='https://raw.githubusercontent.com/Azure-Samples/azure-opensource-labs/main/cloud-native/aks-bicep-keda/01-aks/main.json'
OUTPUT_URL='https://portal.azure.com/#create/Microsoft.Template/uri/'$(printf "$TEMPLATE_URL" | jq -s -R -r @uri )
echo $OUTPUT_URL

# https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2FAzure-Samples%2Fazure-opensource-labs%2Fmain%2Fcloud-native%2Faks-bicep-keda%2F01-aks%2Fmain.json
```
