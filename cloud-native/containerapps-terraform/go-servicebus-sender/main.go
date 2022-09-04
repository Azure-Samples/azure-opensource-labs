package main

import (
	"context"
	"errors"
	"fmt"
	"os"
	"strconv"
	"time"

	"github.com/Azure/azure-sdk-for-go/sdk/messaging/azservicebus"
)

func GetClient() *azservicebus.Client {
	connectionString, ok := os.LookupEnv("AZURE_SERVICEBUS_CONNECTION_STRING") //ex: Endpoint=sb://<YOUR_NAMESPACE>.servicebus.windows.net/;SharedAccessKeyName=RootManageSharedAccessKey;SharedAccessKey=<YOUR_SHARED_ACCESS_KEY>
	if !ok {
		panic("AZURE_SERVICEBUS_CONNECTION_STRING environment variable not found")
	}

	client, err := azservicebus.NewClientFromConnectionString(connectionString, nil)
	if err != nil {
		panic(err)
	}
	return client
}

func SendMessageBatch(messages []string, client *azservicebus.Client) {
	queue, ok := os.LookupEnv("AZURE_SERVICEBUS_QUEUE_NAME") //ex: myqueue
	if !ok {
		panic("AZURE_SERVICEBUS_QUEUE_NAME environment variable not found")
	}
	sender, err := client.NewSender(queue, nil)
	if err != nil {
		panic(err)
	}
	defer sender.Close(context.TODO())

	batch, err := sender.NewMessageBatch(context.TODO(), nil)
	if err != nil {
		panic(err)
	}

	for _, message := range messages {
		err := batch.AddMessage(&azservicebus.Message{Body: []byte(message)}, nil)
		if errors.Is(err, azservicebus.ErrMessageTooLarge) {
			fmt.Printf("Message batch is full. We should send it and create a new one.\n")
		}
	}

	if err := sender.SendMessageBatch(context.TODO(), batch, nil); err != nil {
		panic(err)
	}
}

func main() {
	batchSize, ok := os.LookupEnv("BATCH_SIZE") //ex: 10
	if !ok {
		fmt.Println("batchSize defaulted to 1")
		batchSize = "1"
	}

	batchSizeInt, err := strconv.Atoi(batchSize)
	if err != nil {
		panic(err)
	}

	batchCounter := 0

	client := GetClient()
	for {
		batchCounter++

		// sleep for 1 minutes then double the batch size until it reaches 150
		time.Sleep(1 * time.Minute)

		if batchSizeInt < 150 {
			fmt.Println("doubling the batch size...")
			batchSizeInt = batchSizeInt * 2
		} else {
			fmt.Println("resetting the batch size to 1...")
			batchSizeInt = 1
			// sleep for 30 minutes then start ramping up again
			time.Sleep(30 * time.Minute)
		}

		messages := []string{}
		for i := 1; i <= batchSizeInt; i++ {
			messages = append(messages, "batch "+strconv.Itoa(batchCounter)+" message "+strconv.Itoa(i)+" sent at "+time.Now().String())
		}
		
		fmt.Println("send batch "+strconv.Itoa(batchCounter)+" with "+strconv.Itoa(batchSizeInt)+" messages...")
		SendMessageBatch(messages[:], client)
	}
}