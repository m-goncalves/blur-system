package server

import (
	"encoding/csv"
	"io/ioutil"
	"mime/multipart"
	"os"
	"os/exec"
	"path/filepath"
)

type image struct {
	name string
	size string
	path string
	file multipart.File
}

func (img *image) save() error {
	//writing a temporary file to our server: path + pattern (assigning a random number the file name)
	tempFile, err := ioutil.TempFile("source-images", "upload-*.png")
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
	img.path, err = filepath.Abs(tempFile.Name())
	if err != nil {
		return err
	}

	err = img.saveMetadata()
	if err != nil {
		return err
	}

	// writes "fileBytes" to the temporary file
	_, err = tempFile.Write(fileBytes)

	return err
}

func (img image) saveMetadata() error {
	//creates a file (if non existent) and adds or appends data to it.
	metadataFile, err := os.OpenFile("metadata.csv", os.O_CREATE|os.O_APPEND|os.O_WRONLY, 0644)
	if err != nil {
		return err
	}

	// creates a buffer to the "metadataFile"
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
	return metadataWriter.Write([]string{img.name, img.size, img.path})
}

func (img image) applyBlur() error {
	blurCommand := exec.Command("ruby", "blurImage.rb", img.path)
	blurCommand.Dir = "controller/"
	return blurCommand.Run()
}
