provider "aws" {
    version                    = ">= 2.28.1"
    region                     = var.region
    secret_key                 = var.secret_key
    access_key                 = var.access_key
}

resource "aws_s3_bucket" "terraform_state_blur_bucket"{
  bucket                      = "blur-unique-tf-state-bucket"
  lifecycle {
    prevent_destroy           = true
  }

  versioning {
    enabled                   = true
  }

  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        sse_algorithm         = "AES256"
      }
    }
  }
}

resource "aws_dynamodb_table" "blur_locks" {
  name                        = "blur_locks"
  billing_mode                = "PAY_PER_REQUEST"
  hash_key                    = "LockID"
  attribute {
    name                      = "LockID"
    type                      = "S"
  }
}

terraform {
  backend "s3" {
    bucket                    = "blur-unique-tf-state-bucket"
    key                       = "blur/s3/terraform.tfstate"
    region                    = "sa-east-1"
    dynamodb_table            = "blur_locks"
    encrypt                   = true
  }
}