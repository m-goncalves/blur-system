package server

import (
	"fmt"
	"os"

	"github.com/streadway/amqp"
)

var (
	conn    *amqp.Connection
	channel *amqp.Channel
	queue   amqp.Queue
)

func formatter(err error, msg string) error {
	return fmt.Errorf("%v: %s", err, msg)
}

func init() {

	var err error
	rabbitmq_user := os.Getenv("RABBITMQ_USER")
	rabbitmq_pwd := os.Getenv("RABBITMQ_PWD")
	rabbitmq_host := os.Getenv("RABBITMQ_HOST")
	rabbitmq_port := os.Getenv("RABBITMQ_PORT")
	rabbitmq_queue := os.Getenv("RABBITMQ_QUEUE")

	conn, err := amqp.Dial("amqp://" + rabbitmq_user + ":" + rabbitmq_pwd + "@" + rabbitmq_host + ":" + rabbitmq_port)
	if err != nil {
		logErr(err, "Failed to connect to RabbitMQ")
	}

	// Opening a server channel to process the messages (It makes possible to interact to the rabbitmq instance)
	channel, err = conn.Channel()
	if err != nil {
		logErr(err, "Failed openning a channel")
	}

	//Declaring the queue, which will
	queue, err = channel.QueueDeclare(
		// Assigning a name to the declared queue
		rabbitmq_queue,
		false,
		false,
		false,
		false,
		nil,
	)
	if err != nil {
		logErr(err, "Failed to declare a queue")
	}

}

func sendImage(path string) error {
	// sends the messages to the server
	err := channel.Publish(
		"",
		queue.Name,
		false,
		false,
		amqp.Publishing{
			//type and content of the message to be sent
			ContentType: "text/plain",
			Body:        []byte(path),
		})
	if err != nil {
		return formatter(err, "Failed to publish a message")
	}
	return nil
}
