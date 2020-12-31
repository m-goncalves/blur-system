provider "aws" {
    version                         = ">= 2.28.1"
    region                          = var.region
    secret_key                      = var.secret_key
    access_key                      = var.access_key
}

provider "helm" {
  kubernetes {
    config_path               = "~/.kube/config-blur-cluster"
  }
}

provider "kubernetes" {
  config_context_cluster      = "minikube"
}

module "release-prometheus-operator" {
  source = "OpenQAI/release-prometheus-operator/helm"
  helm_chart_namespace        = "default"
  skip_crds                   =  false
  grafana_image_tag           = "7.0.3"
  grafana_adminPassword       = var.grafana_pwd
  
}

resource "helm_release" "mysql" {
  name                        = "mysql"
  repository                  = "https://charts.bitnami.com/bitnami"
  chart                       = "mysql"
  values                      = [file("../../k8s/mysql/values.yaml")]
}

resource "helm_release" "rabbimq" {
  name                        = "rabbitmq"
  repository                  = "https://charts.bitnami.com/bitnami"
  chart                       = "rabbitmq"
  values                      = [file("../../k8s/rabbitmq/values.yaml")]
}

resource "helm_release" "webservice" {
  name                        = "webservice"
  chart                       = "../../k8s/webservice"
}

resource "helm_release" "worker"{
  name                        = "worker"
  chart                       = "../../k8s/worker"
}

resource "aws_s3_bucket" "terraform_state_blur_bucket"{
  bucket = "blur_unique_tf_state_bucket"
  lifecycle {
    prevent_destroy = true
  }

  versioning {
    enabled = true
  }

  server_side_encryption {
    rule {
      apply_server_side_encryption_by_default {
        sse_algorithm = "AES256"
      }
    }
  }
}

resource "aws_dynamodb_table"