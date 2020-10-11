FROM golang:1.15.2

LABEL version="0.0.1"

LABEL maintainer="mjg"

WORKDIR /go/src/github.com/m-goncalves/webservice

COPY server/  server/

COPY cmd/ cmd/

COPY index.html .

RUN GOBIN=/go/bin go install cmd/webservice/webservice.go

ENTRYPOINT /go/bin/webservice

EXPOSE 8080

VOLUME [ "/source-images", "/blurred-images" ]


