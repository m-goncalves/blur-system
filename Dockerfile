FROM golang:1.15.2-alpine3.12 AS builder

LABEL version="0.0.1"

WORKDIR /go/src/github.com/m-goncalves/webservice

ADD go.mod .

ADD go.sum .

RUN go mod download

COPY . .

RUN go build -o blur-service cmd/webservice/webservice.go

FROM alpine:3.12 

WORKDIR /go/src/github.com/m-goncalves/webservice

COPY --from=builder /go/src/github.com/m-goncalves/webservice/index.html .

COPY --from=builder /go/src/github.com/m-goncalves/webservice/blur-service . 

EXPOSE 8080

ENTRYPOINT ./blur-service

VOLUME ["/source-images"]

