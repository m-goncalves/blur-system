package server

import (
	"fmt"

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
	conn, err = amqp.Dial("amqp://guest:guest@rabbitmq:5672") // Access to linked rabbitmq host
	if err != nil {
		logErr(err, "Failed to connect to RabbitMQ")
	}

	channel, err = conn.Channel()
	if err != nil {
		logErr(err, "Failed to open a channel")
	}

	queue, err = channel.QueueDeclare(
		"blur-service",
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
	err := channel.Publish(
		"",
		queue.Name,
		false,
		false,
		amqp.Publishing{
			ContentType: "text/plain",
			Body:        []byte(path),
		})
	if err != nil {
		return formatter(err, "Failed to publish a message")
	}
	return nil
}
