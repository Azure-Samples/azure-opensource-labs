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