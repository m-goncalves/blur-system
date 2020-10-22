
FROM golang:1.15.2-alpine3.12 

LABEL version="0.0.1"

WORKDIR /go/src/github.com/m-goncalves/webservice

ADD go.mod .

ADD go.sum .

RUN go mod download

COPY . .

RUN go build -o blur-service cmd/webservice/webservice.go
                            
ENTRYPOINT ./blur-service

EXPOSE 8080 5672

VOLUME ["/source-images"]


