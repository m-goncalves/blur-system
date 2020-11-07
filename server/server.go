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

//retrieving a post request of an image and saves it in a folder called "blurred_images."
func Blur(w http.ResponseWriter, r *http.Request) {
	//parsing the whole request body. Specifying the limits of the upload (10MB).
	err := r.ParseMultipartForm(10 << 20)
	if err != nil {
		logErr(err, "Error parsing image file")
	}

	// assigning the image and the metadata to the variables "file" and "handler". "FormFile" returns the first file provided by the specified key ('image-file')."
	file, handler, err := r.FormFile("image-file")
	if err != nil {
		w.Write([]byte("Error retrieving file"))
		logErr(err, "Error retrieving the file")
		return
	}
	defer file.Close() // postpone the closing of the file until the end of the function.

	// assigning the bellow values to the struct "image" and the struct itself to the variable "img".
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

	// showing to the user that the upload was successful.
	fmt.Fprintf(w, "File successfully uploaded\n")
}

//mapping the file which must be handled by the funtion "http.HandleFunc"
func UserInterface(w http.ResponseWriter, r *http.Request) {
	index, err := ioutil.ReadFile("index.html")
	if err != nil {
		logErr(err, "Cannot read index file")
	}

	w.Write(index)
}
