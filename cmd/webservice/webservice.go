package main

import (
	"fmt"
	"log"
	"net/http"

	"github.com/m-goncalves/webservice/server"
)

func main() {
	// setting up the routes (home and upload).
	port := "8080"
	http.HandleFunc("/", server.UserInterface)
	http.HandleFunc("/blur", server.Blur)
	log.Println("serving on port:", port)
	err := http.ListenAndServe(":8080", nil)
	if err != nil {
		panic(fmt.Sprintf("server stoped running %s", err))
	}
}
