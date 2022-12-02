RESOURCE_GROUP ?= 221100-vm-flatcar
LOCATION ?= eastus

all: group empty deploy

group:
	az group create \
		--name ${RESOURCE_GROUP} \
		--location ${LOCATION}

deploy:
	az deployment group create \
		--resource-group ${RESOURCE_GROUP} \
		--template-file vm.bicep

empty:
	az deployment group create \
		--resource-group ${RESOURCE_GROUP} \
		--template-file empty.bicep \
		--mode Complete

arm:
	az bicep build -f vm.bicep
	git add vm.json
	git commit -m "Update vm.json"
	git push

BRANCH_OR_COMMIT ?= linux-flatcar
# BRANCH_OR_COMMIT=$(git rev-parse HEAD)
portal-url:
	@TEMPLATE_URL="https://raw.githubusercontent.com/Azure-Samples/azure-opensource-labs/${BRANCH_OR_COMMIT}/linux/vm-flatcar/vm.json"; \
	OUTPUT_URL='https://portal.azure.com/#create/Microsoft.Template/uri/'; \
	TEMPLATE_URL_ENCODED=$$(printf "$$TEMPLATE_URL" | jq -s -R -r @uri); \
	echo $$OUTPUT_URL$$TEMPLATE_URL_ENCODED
