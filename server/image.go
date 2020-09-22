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
	tempFile, err := ioutil.TempFile("imagens", "upload-*.png")
	if err != nil {
		return err
	}
	defer tempFile.Close()

	fileBytes, err := ioutil.ReadAll(img.file)
	if err != nil {
		return err
	}

	err = img.saveMetadata(tempFile.Name())
	if err != nil {
		return err
	}

	// write this byte array to our temporary file
	_, err = tempFile.Write(fileBytes)

	return err
}

func (img image) saveMetadata(sourceFilename string) error {
	metadataFile, err := os.OpenFile("metadata.csv", os.O_CREATE|os.O_APPEND|os.O_WRONLY, 0666)
	if err != nil {
		return err
	}

	metadataWriter := csv.NewWriter(metadataFile)
	defer metadataWriter.Flush()

	fileStat, err := metadataFile.Stat()
	if err != nil {
		return err
	}
	if size := fileStat.Size(); size == 0 {
		err = metadataWriter.Write([]string{"name", "size", "path"})
		if err != nil {
			return err
		}
	}

	return metadataWriter.Write([]string{img.name, img.size, sourceFilename})
}
