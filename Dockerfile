# The "alpine" points to the latest version of the image, which 
# changes constantly and may cause problems in the future. 
# Alpine is not officiallysupported by the Go project
FROM golang:1.15.2

LABEL version="0.0.1"

WORKDIR /go/src/github.com/m-goncalves/webservice

# It's considered a good practice to copy the package managers
# of the specific language first. This optimizes the build time.
#COPY go.mod go.sum ./

COPY . .
# Downloading the dependencies of the project
RUN go mod download

# "go get github.com/streadway/amqp" this would be redundant 
# now that the dependency was already downloaded by the go module
# "apk add git" golang official images have already git installed 
RUN GOBIN=/go/bin go install cmd/webservice/webservice.go

ENTRYPOINT /go/bin/webservice

EXPOSE 8080 5672

VOLUME ["/source-images"]


