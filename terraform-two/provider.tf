provider "aws" {
    version = ">= 2.28.1"
    region = var.region
    secret_key = var.secret_key
    access_key = var.access_key
}