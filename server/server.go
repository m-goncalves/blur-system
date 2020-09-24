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

//retrieves a posts request of an image and saves it in a folder called "imagens/."
func Upload(w http.ResponseWriter, r *http.Request) {
	r.ParseMultipartForm(10 << 20)

	// the image and the metadata are assigned to the variables "file and handler."
	file, handler, err := r.FormFile("image-file")
	if err != nil {
		logErr(err, "Error retrieving the file")
		return
	}
	defer file.Close()

	// Saving the image in the folder  "imagens" and  the metadata in the file "metadata.csv."
	err = image{
		name: handler.Filename,
		size: fmt.Sprintf("%d", handler.Size),
		file: file,
	}.save()

	if err != nil {
		logErr(err, "Error saving file")
	}

	// Shows to the user that the upload was successful.
	fmt.Fprintf(w, "File successfully uploaded\n")
}

func GetFile(w http.ResponseWriter, r *http.Request) {
	index, err := ioutil.ReadFile("index.html")
	if err != nil {
		logErr(err, "Cannot read index file")
	}

	w.Write(index)
}
