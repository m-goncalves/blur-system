package main

import (
	"log"
	"net/http"

	"github.com/m-goncalves/webservice/server"
)

func main() {
	// setting up the routes (home and upload).
	port := "8080"
	http.HandleFunc("/", server.UserInterface)
	http.HandleFunc("/upload", server.Blur)
	log.Println("serving on port:", port)
	//setting up port to listen on.
	http.ListenAndServe(":8080", nil)
}
