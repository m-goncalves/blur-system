
provider "helm" {
    kubernetes {
        config_path         = "~/.kube/config-blur-cluster"
    }
}

resource "helm_release" "blur-mysql" {
  name                    = "blur-mysql"
  chart                   = "mysql"
  repository              = "https://charts.bitnami.com/bitnami"
  values                  = [file("../../k8s/mysql/values.yaml")]
} 

resource "helm_release" "blur-rabbitmq" {
  name                    = "blur-rabbitmq"
  chart                   = "rabbitmq"
  repository              = "https://charts.bitnami.com/bitnami"
  values                  = [file("../../k8s/rabbitmq/values.yaml")]
} 

resource "helm_release" "blur-webservice" {
  name                      = "blur-webservice"
  chart                     = "../../k8s/webservice"
}

resource "helm_release" "worker" {
  name                      = "worker"
  chart                     = "../../k8s/worker"
}

module "release-prometheus-operator" {
  source                    = "OpenQAI/release-prometheus-operator/helm"
  helm_chart_namespace      = "default"
  skip_crds                 =  false
  grafana_image_tag         = "7.0.3"
  grafana_adminPassword     = var.grafana_pwd  
}