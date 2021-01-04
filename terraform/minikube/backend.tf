terraform {
  backend "s3" {
    bucket                    = "blur-tf-state-bucket"
    key                       = "aws/testing/terraform.tfstate"
    region                    = "sa-east-1"
    dynamodb_table            = "blur_locks"
    encrypt                   = true
  }
}