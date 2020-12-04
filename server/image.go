package server

import (
	"fmt"
	"mime/multipart"
	"os"
	"strings"
	"time"

	"github.com/aws/aws-sdk-go/service/s3"
	"github.com/aws/aws-sdk-go/service/s3/s3manager"

	"github.com/aws/aws-sdk-go/aws"
	"github.com/aws/aws-sdk-go/aws/awserr"
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
	num  int
	file multipart.File
}

type Image_metadata struct {
	//gorm.Model
	ID        int
	Name      string
	Size      int
	Url       string
	CreatedAt time.Time
}

var (
	dbConnection string
	database     string
	table        string
	sess         *session.Session
)

func init() {
	region := os.Getenv("AWS_REGION")
	user := os.Getenv("MYSQL_USER")
	pwd := os.Getenv("MYSQL_PASSWORD")
	database = os.Getenv("MYSQL_DATABASE")
	table = os.Getenv("MYSQL_METADATA_TABLE")
	master := os.Getenv("MYSQL_MASTER")

	dbConnection = fmt.Sprintf("%s:%s@tcp(%s)/%s?charset=utf8mb4&parseTime=True&loc=Local", user, pwd, master, database)

	db, err := gorm.Open(mysql.Open(dbConnection), &gorm.Config{})
	sqlDB, err := db.DB()
	if err != nil {
		logErr(err, "Unable to access the database!")
	}

	db.AutoMigrate(&Image_metadata{})

	defer sqlDB.Close()
	sess, err = session.NewSession(&aws.Config{
		Credentials: credentials.NewEnvCredentials(),
		Region:      aws.String(region),
	})
	if err != nil {
		logErr(err, "Unable to create session!")
	}
}
func (img *image) save() error {
	bucket := os.Getenv("AWS_BUCKET")

	img.checkKey(bucket, img.genS3Key("blurred-images"))

	uploader := s3manager.NewUploader(sess)

	result, err := uploader.Upload(&s3manager.UploadInput{
		Bucket: aws.String(bucket),
		Key:    aws.String(img.key),
		Body:   img.file,
	})
	if err != nil {
		return err
	}

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

func (img image) genS3Key(dir string) string {
	if img.num == 0 {
		return fmt.Sprintf("/%s/%s", dir, img.name)
	}

	ext := strings.LastIndex(img.name, ".")
	return fmt.Sprintf("/%s/%s(%d)%s", dir, img.name[:ext], img.num, img.name[ext:])
}

func s3objectExists(bucket, key string) (bool, error) {
	svc := s3.New(sess)
	_, err := svc.GetObject(&s3.GetObjectInput{
		Bucket: aws.String(bucket),
		Key:    aws.String(key),
	})

	if err != nil {
		if aerr, ok := err.(awserr.Error); ok && aerr.Code() == s3.ErrCodeNoSuchKey {
			return false, nil
		}
		return false, err
	}

	return true, nil
}

func (img *image) checkKey(bucket, key string) error {
	exists, err := s3objectExists(bucket, key)
	if err != nil {
		return err
	}

	if exists {
		img.num++
		return img.checkKey(bucket, img.genS3Key("blurred-images"))
	}

	img.key = img.genS3Key("source-images")

	return nil
}
