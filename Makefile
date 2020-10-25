build:
	docker build -t blur-service .
	cd controller && docker build -t blur-worker .

rabbitmq:
	docker run \
		--rm \
		--name rabbitmq \
		--network net-blur \
		-p 5672:5672 \
		-p 15672:15672 \
		rabbitmq:3-alpine
run:
	docker run \
		--rm \
		--name blur-service \
		--network net-blur \
		--mount type=bind,source=/Users/marcelo/source-images,target=/source-images \
		-p 8080:8080 \
		blur-service &
	docker run \
		--name blur-worker \
		--network net-blur \
		--mount type=bind,source=/Users/marcelo/source-images,target=/source-images \
		--mount type=bind,source=/Users/marcelo/blurred-images,target=/blurred-images \
		blur-worker

stop:
	docker stop blur-service
	docker stop blur-worker

		
# docker run --rm --name rabbitmq --network net-blur -p 5672:5672 -p 15672:15672 rabbitmq:3-alpine
# docker run --rm --name blur-service --network net-blur --mount type=bind,source=/Users/marcelo/Desktop/source-images,target=/source-images -p 8080:8080 blur-service
# docker run --rm --name blur-worker --network net-blur --mount type=bind,source=/Users/marcelo/Desktop/source-images,target=/source-images --mount type=bind,source=/Users/marcelo/Desktop/blurred-images,target=/blurred-images blur-worker

# docker run --rm --name blur-service --network net-blur -v source-images:/source-images -p 8080:8080 blur-service
