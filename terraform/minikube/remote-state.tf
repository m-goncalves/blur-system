provider "aws" {
    version                    = ">= 2.28.1"
    region                     = var.region
    secret_key                 = var.secret_key
    access_key                 = var.access_key
}

resource "aws_s3_bucket" "blur-tf-state-bucket"{
  bucket                      = "blur-tf-state-bucket"
  lifecycle {
    prevent_destroy           = false
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