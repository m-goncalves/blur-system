package main

import (
	"net/http"

	"github.com/m-goncalves/webservice/server"
)

func main() {
	http.HandleFunc("/", server.GetFile)
	http.HandleFunc("/upload", server.Upload)
	http.ListenAndServe(":8080", nil)
}
