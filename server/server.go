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

func Upload(w http.ResponseWriter, r *http.Request) {
	r.ParseMultipartForm(10 << 10)

	file, handler, err := r.FormFile("image-file")
	if err != nil {
		logErr(err, "Error retrieving the file!")
		return
	}
	defer file.Close()

	err = image{
		name: handler.Filename,
		size: fmt.Sprintf("%d", handler.Size),
		file: file,
	}.save()

	if err != nil {
		logErr(err, "Error saving file!")
	}

	fmt.Fprint(w, "File successfully uploaded\n")
}

func GetFile(w http.ResponseWriter, r *http.Request) {
	index, err := ioutil.ReadFile("index.html")
	if err != nil {
		logErr(err, "Cannot read file!")
	}

	w.Write(index)
}
