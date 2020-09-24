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

//retrieving a posts request of an image and saves it in a folder called "imagens/."
func Upload(w http.ResponseWriter, r *http.Request) {
	//parses the whole request body. Specifies the limits of the upload (10MB).
	r.ParseMultipartForm(10 << 20)

	// assigning the image and the metadata to the variables "file" and "handler". "FormFile" returns the first file provided by the specified key ('image-file')"
	file, handler, err := r.FormFile("image-file")
	if err != nil {
		logErr(err, "Error retrieving the file")
		return
	}
	defer file.Close() // postpone the closing of the file until the end of the function.

	// assigning the bellow values to the struct and calling the function save() on it.
	err = image{
		name: handler.Filename,
		size: fmt.Sprintf("%d", handler.Size), // "Sprint" formats but doesn't print the value.
		file: file,
	}.save()

	if err != nil {
		logErr(err, "Error saving file")
	}

	// showing to the user that the upload was successful.
	fmt.Fprintf(w, "File successfully uploaded\n")
}

//mapping the file which must be handled by the funtion "http.HandleFunc"
func GetFile(w http.ResponseWriter, r *http.Request) {
	index, err := ioutil.ReadFile("index.html")
	if err != nil {
		logErr(err, "Cannot read index file")
	}

	w.Write(index)
}
