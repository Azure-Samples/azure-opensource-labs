# helper snippets which can be sourced to use the functions below

RESOURCE_GROUP='220500-azure-linux'
LOCATION='eastus'

function a-deploy {
	az deployment group create --resource-group $RESOURCE_GROUP --template-file azuredeploy.json
}

function a-deploy-key {
	! [[ -z "${1:-}" ]] && local PASSWORD_OR_KEY="$1"
	[[ -z "${PASSWORD_OR_KEY:-}" ]] && local PASSWORD_OR_KEY="$(cat ~/.ssh/id_rsa_tmp.pub)"

	az deployment group create --resource-group $RESOURCE_GROUP --template-file azuredeploy.json \
	    --parameters adminPasswordOrKey="$PASSWORD_OR_KEY"
}

function a-deploy-init {
	! [[ -z "${1:-}" ]] && local PASSWORD_OR_KEY="$1"
	[[ -z "${PASSWORD_OR_KEY:-}" ]] && local PASSWORD_OR_KEY="$(cat ~/.ssh/id_rsa_tmp.pub)"

	# get IP from azure instance metadata service
	# https://docs.microsoft.com/en-us/azure/virtual-machines/linux/instance-metadata-service#accessing-azure-instance-metadata-service
	IP_ALLOW=$(curl -H Metadata:true --noproxy "*" 'http://169.254.169.254/metadata/instance?api-version=2020-06-01' | jq -r '.network.interface[0].ipv4.ipAddress[0].publicIpAddress')
	az deployment group create --resource-group $RESOURCE_GROUP --template-file azuredeploy.json \
	    --parameters \
	    	adminPasswordOrKey="$PASSWORD_OR_KEY" \
		allowIpPort22="$IP_ALLOW" 
        	customDataUrl='https://raw.githubusercontent.com/Azure-Samples/azure-opensource-labs/linux-vmss/linux/vmss/cloud-init/cloud-init.sh'
}

function a-deploy-share1 {
	! [[ -z "${1:-}" ]] && local PASSWORD_OR_KEY="$1"
	[[ -z "${PASSWORD_OR_KEY:-}" ]] && local PASSWORD_OR_KEY="$(cat ~/.ssh/id_rsa_tmp.pub)"

	# get IP from azure instance metadata service
	# https://docs.microsoft.com/en-us/azure/virtual-machines/linux/instance-metadata-service#accessing-azure-instance-metadata-service
	IP_ALLOW=$(curl -s -H Metadata:true --noproxy "*" 'http://169.254.169.254/metadata/instance?api-version=2020-06-01' | jq -r '.network.interface[0].ipv4.ipAddress[0].publicIpAddress')

	VMSS_NAME='share1'

	az deployment group create --resource-group $RESOURCE_GROUP --template-file azuredeploy.json \
	    --parameters \
		vmssName=$VMSS_NAME \
		vmSize='Standard_DS1_v2' \
		adminPasswordOrKey="$PASSWORD_OR_KEY" \
		allowIpPort22="$IP_ALLOW" \
		customDataUrl='https://raw.githubusercontent.com/Azure-Samples/azure-opensource-labs/linux-vmss/linux/vmss/cloud-init/cloud-init.sh' \
		env="$ENV_JSON"

}

function a-deploy-empty {
	! [[ -z "${1:-}" ]] && local RESOURCE_GROUP="$1"
	! [[ -z "${2:-}" ]] && local LOCATION="$2"

	az deployment group create --resource-group $RESOURCE_GROUP --template-file empty.json \
		--mode Complete
}

function a-ssh {
	[[ -z "${ID_RSA:-}" ]] && local ID_RSA="~/.ssh/id_rsa.pub"
	
	ssh $1 \
	    -i $ID_RSA \
	    -o UserKnownHostsFile=/dev/null \
	    -o StrictHostKeyChecking=no
}

function a-ssh-port {
	[[ -z "${ID_RSA:-}" ]] && local ID_RSA="~/.ssh/id_rsa.pub"
	
	ssh $1 \
	    -i $ID_RSA \
	    -o UserKnownHostsFile=/dev/null \
	    -o StrictHostKeyChecking=no \
	    -p $2
}

