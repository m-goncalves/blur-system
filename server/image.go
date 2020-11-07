package server

import (
	"fmt"
	"io/ioutil"
	"mime/multipart"
	"os"
	"time"

	"github.com/aws/aws-sdk-go/service/s3/s3manager"

	"github.com/aws/aws-sdk-go/aws"
	"github.com/aws/aws-sdk-go/aws/credentials"
	"github.com/aws/aws-sdk-go/aws/session"
	_ "github.com/go-sql-driver/mysql"
	"gorm.io/driver/mysql"
	"gorm.io/gorm"
)

type image struct {
	name string
	size int
	path string
	key  string
	file multipart.File
}

type Image_metadata struct {
	gorm.Model
	ID        int
	Name      string
	Size      int
	Url       string
	CreatedAt time.Time
}

var (
	dbConnection string
	database     string
	//table        string
	sess *session.Session
)

func init() {
	//PASSAR CREDENCIAIS NO DOCKER COMPOSEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEE
	region := os.Getenv("REGION")
	user := os.Getenv("MYSQL_USER")
	pwd := os.Getenv("MYSQL_PASSWORD")
	database = os.Getenv("MYSQL_DATABASE")
	//table = os.Getenv("MYSQL_METADATA_TABLE")
	dbConnection = fmt.Sprintf("%s:%s@tcp(mysql)/%s?charset=utf8mb4&parseTime=True&loc=Local", user, pwd, database)

	db, err := gorm.Open(mysql.Open(dbConnection), &gorm.Config{})
	sqlDB, err := db.DB()
	if err != nil {
		logErr(err, "Unable to access the database!")
	}

	db.AutoMigrate(&Image_metadata{})

	defer sqlDB.Close()
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
	db, err := gorm.Open(mysql.Open(dbConnection), &gorm.Config{})
	if err != nil {
		return err
	}

	sqlDB, err := db.DB()
	if err != nil {
		return err
	}

	defer sqlDB.Close()
	result := db.Create(&Image_metadata{Name: img.name, Size: img.size, Url: img.path})

	return result.Error

}
