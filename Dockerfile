FROM golang:alpine

LABEL version="0.0.1"

WORKDIR /go/src/github.com/m-goncalves/webservice

COPY . .

RUN apk add git \
    && go get github.com/streadway/amqp \
    && GOBIN=/go/bin go install cmd/webservice/webservice.go

ENTRYPOINT /go/bin/webservice

EXPOSE 8080 5672

VOLUME ["/source-images"]


