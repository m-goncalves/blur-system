password=$(pwd)
database=$(db)
export password
export database
export user
# build will build docker images
build:
	docker build -t blur-service .
	cd controller && docker build -t blur-worker .
	cd sql && docker build -t blur-mysql .

runmysql:
	docker run \
		--rm \
		--name blur-mysql \
		--network net-blur \
		-e MYSQL_USER=blur-user \
		-e MYSQL_ROOT_PASSWORD=password \
		-e MYSQL_DATABASE=metadata-db \
		-e MYSQL_PASSWORD=password \
		--mount type=bind,source=/Users/marcelo/Desktop/blur-mysql,target=/var/lib/mysql \
		blur-mysql

rabbitmq:
	docker run \
		-d \
		-it \
		--rm \
		--name blur-rabbitmq \
		--network net-blur \
		-p 5672:5672 \
		-p 15672:15672 \
		rabbitmq:3-management

runservice:
	docker run \
	    --rm \
		--name blur-service \
		--network net-blur \
		-p 8080:8080 \
		-e MYSQL_USER=blur-user \
		-e MYSQL_METADATA_TABLE=source_images_metadata \
		-e AMQP_URL=amqp://guest:guest@blur-rabbitmq:5672 \
		-e AWS_BUCKET=blur-service-bucket \
		-e MYSQL_DATABASE=metadata-db \
		-e AWS_REGION=sa-east-1 \
		-e MYSQL_METADATA_TABLE=source_images_metadata \
		-e MYSQL_PASSWORD=password \
		-e AWS_ACCESS_KEY_ID=AKIAZZLHXBMXRLMONZ6Y \
		-e AWS_SECRET_ACCESS_KEY=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 \
		--mount type=bind,source=/Users/marcelo/Desktop/source-images,target=/source-images \
		--mount type=bind,source=/Users/marcelo/.aws/,target=/home/webservice/.aws/ \
		blur-service
		

runworker:
	docker run \
		--rm \
		--name blur-worker \
		--network net-blur \
		--mount type=bind,source=/home/oak/.aws/,target=/root/.aws/ \
		blur-worker

run: runservice runworker

stopservice:
	docker container stop blur-service

stopworker:
	docker container stop blur-worker

stopmysql:
	docker container stop blur-mysql

stop: stopservice stopworker

		
# docker run --rm --name blur-rabbitmq --network net-blur -p 5672:5672 -p 15672:15672 rabbitmq:3-alpine
# docker run --rm --name blur-service -e AMQP_URL=amqp://guest:guest@blur-rabbitmq:5672 -e MYSQL_USER=blur-user -e AWS_BUCKET=blur-service-bucket -e MYSQL_DATABASE=metadata-db -e AWS_REGION=sa-east-1 -e MYSQL_METADATA_TABLE=source_images_metadata -e MYSQL_PASSWORD=password --network net-blur --mount type=bind,source=/Users/marcelo/Desktop/source-images,target=/source-images -p 8080:8080 blur-service
# docker run --rm --name blur-worker --network net-blur --mount type=bind,source=/Users/marcelo/Desktop/source-images,target=/source-images --mount type=bind,source=/Users/marcelo/Desktop/blurred-images,target=/blurred-images blur-worker

# docker run --rm --name blur-service --network net-blur -v source-images:/source-images -p 8080:8080 blur-service

AMQP_URL: ${AMQP_URL}
            MYSQL_USER: ${MYSQL_USER}
            MYSQL_PASSWORD: ${MYSQL_PASSWORD}
            MYSQL_DATABASE: ${MYSQL_DATABASE}
            MYSQL_METADATA_TABLE: ${MYSQL_METADATA_TABLE}
            AWS_ACCESS_KEY_ID: ${AWS_ACCESS_KEY_ID}
            AWS_SECRET_ACCESS_KEY: ${AWS_SECRET_ACCESS_KEY}
            AWS_REGION: ${AWS_REGION}
            AWS_BUCKET: ${AWS_BUCKET}
