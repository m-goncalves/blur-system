package server

import (
	"database/sql"
	"fmt"
	"io/ioutil"
	"mime/multipart"
	"os"

	"github.com/aws/aws-sdk-go/service/s3/s3manager"

	"github.com/aws/aws-sdk-go/aws"
	"github.com/aws/aws-sdk-go/aws/credentials"
	"github.com/aws/aws-sdk-go/aws/session"
	_ "github.com/go-sql-driver/mysql"
)

type image struct {
	name string
	size string
	path string
	key  string
	file multipart.File
}

var (
	dbConnection string
	database     string
	table        string
	sess         *session.Session
)

func init() {
	//PASSAR CREDENCIAIS NO DOCKER COMPOSEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEE
	region := os.Getenv("REGION")
	user := os.Getenv("MYSQL_USER")
	pwd := os.Getenv("MYSQL_PASSWORD")
	database = os.Getenv("MYSQL_DATABASE")
	table = os.Getenv("MYSQL_METADATA_TABLE")
	dbConnection = fmt.Sprintf("%s:%s@tcp(blur-mysql)/%s", user, pwd, database)

	var err error
	sess, err = session.NewSession(&aws.Config{
		Credentials: credentials.NewEnvCredentials(), //PASSAR CREDENCIAIS NO DOCKER COMPOSEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEE
		Region:      aws.String(region),
	})
	if err != nil {
		logErr(err, "Unable to create session!")
	}
}
func (img *image) save() error {
	//writing a temporary file to our server: path + pattern (assigning a random number the file name)
	bucket := os.Getenv("AWS_BUCKET")
	tempFile, err := ioutil.TempFile(os.Getenv("SOURCEDIR"), "upload-*.png")
	if err != nil {
		return err
	}
	defer tempFile.Close()

	img.key = tempFile.Name()
	uploader := s3manager.NewUploader(sess)

	result, err := uploader.Upload(&s3manager.UploadInput{
		Bucket: aws.String(bucket),
		Key:    aws.String(img.key),
		Body:   img.file,
	})
	if err != nil {
		return err
	}

	// saves the metadata
	img.path = result.Location
	err = img.saveMetadataMysql()
	if err != nil {
		return err
	}

	return err
}

func (img image) saveMetadataMysql() error {
	db, err := sql.Open("mysql", dbConnection)
	if err != nil {
		return err
	}
	defer db.Close()

	statement, err := db.Prepare(fmt.Sprintf("INSERT %s SET name=?, size=?, url=?", table))
	if err != nil {
		return err
	}

	_, err = statement.Exec(img.name, img.size, img.path)
	return err

}
