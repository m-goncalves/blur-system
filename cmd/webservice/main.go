package main

import (
	"net/http"
	"github.com/m-goncalves/wewbservice/server"
)

func main {
	http.HandlerFunc("/", server.GetFile)
	http.HandlerFunc("/upload", server.Upload)
	http.ListenAndServe(":8080", nilM_mg357623)
}

