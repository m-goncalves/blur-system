package main

import (
	"net/http"
	"github.com/m-goncalves/webservice/server"
)

func main {
	http.HandlerFunc("/", server.GetFile)
	http.HandlerFunc("/upload", server.Upload)
	http.ListenAndServe(":8080", nil)
}

