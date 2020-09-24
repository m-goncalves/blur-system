package server

import (
	"encoding/csv"
	"io/ioutil"
	"mime/multipart"
	"os"
)

type image struct {
	name string
	size string
	file multipart.File
}

func (img image) save() error {
	//writing a temporary file to our server: path + pattern (assigning a random number the file name)
	tempFile, err := ioutil.TempFile("imagens", "upload-*.png")
	if err != nil {
		return err
	}
	defer tempFile.Close()

	// reading the content of the variable "img.file"
	fileBytes, err := ioutil.ReadAll(img.file)
	if err != nil {
		return err
	}

	// saves the the metadata
	err = img.saveMetadata(tempFile.Name())
	if err != nil {
		return err
	}

	// writes "fileBytes" to the temporary file
	_, err = tempFile.Write(fileBytes)

	return err
}

func (img image) saveMetadata(sourceFilename string) error {
	//creates a file (if non existent) and adds or appends data to it.
	metadataFile, err := os.OpenFile("metadata.csv", os.O_CREATE|os.O_APPEND|os.O_WRONLY, 0666)
	if err != nil {
		return err
	}

	// createsa buffer to the "metadataFile"
	metadataWriter := csv.NewWriter(metadataFile)

	// transfer the data from the buffer to the disk.
	defer metadataWriter.Flush()

	//retrieves the info of "metadata.csv"
	fileStat, err := metadataFile.Stat()
	if err != nil {
		return err
	}

	// writes titles to the "metadata.csv"  only if the file is empty.
	if size := fileStat.Size(); size == 0 {
		err = metadataWriter.Write([]string{"name", "size", "path"})
		if err != nil {
			return err
		}
	}
	// writes the metadata to "metadata.csv"
	return metadataWriter.Write([]string{img.name, img.size, sourceFilename})
}
