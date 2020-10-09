FROM golang

LABEL version="0.0.1"

LABEL maintainer="mgoncalves@anynines.com"

WORKDIR /

RUN mkdir -p source-images blurred-images

WORKDIR /go/src/github.com/m-goncalves/webservice

COPY server/  server/

COPY cmd/ cmd/

COPY index.html .

RUN GOBIN=/go/bin go install cmd/webservice/webservice.go

ENTRYPOINT /go/bin/webservice

EXPOSE 8080


