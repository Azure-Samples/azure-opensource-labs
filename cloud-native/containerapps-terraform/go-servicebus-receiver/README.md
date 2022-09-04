# go-azure-service-bus-receiver

Command notes

```bash
# initialize the project
go mod init go-azure-service-bus-receiver

# get dependencies
go get github.com/Azure/azure-sdk-for-go/sdk/azidentity
go get github.com/Azure/azure-sdk-for-go/sdk/messaging/azservicebus

# set some environment variables
export AZURE_SERVICEBUS_CONNECTION_STRING="Endpoint=sb://<YOUR_NAMESPACE>.servicebus.windows.net/;SharedAccessKeyName=RootManageSharedAccessKey;SharedAccessKey=<YOUR_SHARED_ACCESS_KEY>"
export AZURE_SERVICEBUS_QUEUE_NAME="myqueue"
export BATCH_SIZE=2

# run the app locally
go run main.go

# build the docker container
docker build -t go-azure-service-bus-receiver:v0.0.1 .

# run the docker container
docker run -e AZURE_SERVICEBUS_CONNECTION_STRING="Endpoint=sb://gogoaca.servicebus.windows.net/;SharedAccessKeyName=RootManageSharedAccessKey;SharedAccessKey=kTSEW7WbXXSa4QShfC5aLS2L+aVOs0iHjI+k+jwxxs4=" -e AZURE_SERVICEBUS_QUEUE_NAME=myqueue -e BATCH_SIZE=10 go-azure-service-bus-receiver:v0.0.1
```
