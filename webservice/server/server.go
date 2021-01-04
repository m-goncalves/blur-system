package server

import (
	"fmt"
	"io/ioutil"
	"log"
	"net/http"
)

func logErr(err error, msg string) {
	log.Fatalf("%s: %s", err, msg)
}

func Blur(w http.ResponseWriter, r *http.Request) {
	err := r.ParseMultipartForm(10 << 20)
	if err != nil {
		logErr(err, "Error parsing image file")
	}

	file, handler, err := r.FormFile("image-file")
	if err != nil {
		w.Write([]byte("Error retrieving file"))
		logErr(err, "Error retrieving the file")
		return
	}
	defer file.Close()

	img := image{
		name: handler.Filename,
		size: int(handler.Size),
		file: file,
	}

	err = img.save()
	if err != nil {
		logErr(err, "Error saving file")
		return
	}

	err = sendImage(img.key)
	if err != nil {
		logErr(err, "Error sending message")
	}

	fmt.Fprintf(w, "File successfully uploaded\n")
}

func UserInterface(w http.ResponseWriter, r *http.Request) {
	index, err := ioutil.ReadFile("index.html")
	if err != nil {
		logErr(err, "Cannot read index file")
	}

	w.Write(index)
}
