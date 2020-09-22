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

// Upload é uma função que recebe o POST de um arquivo de imagem menor que 10MB e salva o arquivo em no diretório "imagens/"
func Upload(w http.ResponseWriter, r *http.Request) {
	r.ParseMultipartForm(10 << 20)

	// Aqui a imagem é salva na variável file e os metadados em handler
	file, handler, err := r.FormFile("image-file")
	if err != nil {
		logErr(err, "Error retrieving the file")
		return
	}
	defer file.Close()

	// Salva a imagem na pasta imagens e suas informações no arquivo metadata.csv
	err = image{
		name: handler.Filename,
		size: fmt.Sprintf("%d", handler.Size),
		file: file,
	}.save()

	if err != nil {
		logErr(err, "Error saving file")
	}

	// return that we have successfully uploaded our file!
	fmt.Fprintf(w, "File successfully uploaded\n")
}

func GetFile(w http.ResponseWriter, r *http.Request) {
	index, err := ioutil.ReadFile("index.html")
	if err != nil {
		logErr(err, "Cannot read index file")
	}

	w.Write(index)
}
