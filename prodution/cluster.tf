terraform {
  required_version = ">= 0.14.0"
}
provider "aws" {
    version                         = ">= 2.28.1"
    region                          = var.region
    secret_key                      = var.secret_key
    access_key                      = var.access_key
}

module "eks" {
  source       = "terraform-aws-modules/eks/aws"
  cluster_name                      = var.cluster_name
  cluster_version                   = "1.17"
  # Using the private subnets so that the nodes 
  # are not directly accessible from outside.
  subnets                           = module.vpc.private_subnets
  version = "12.2.0"
  cluster_create_timeout            = "1h"
  cluster_endpoint_private_access   = true 
  vpc_id                            = module.vpc.vpc_id
  wait_for_cluster_cmd              = "until curl -k -s $ENDPOINT/healthz >/dev/null; do sleep 4; done"
  
  worker_groups = [
    {
      name                          = "worker-group"
      instance_type                 = "t2.micro"
      asg_desired_capacity          = 8
      additional_security_group_ids = [aws_security_group.security_group.id]
    },
  ]
}

data "aws_eks_cluster" "blur_cluster" {
  name                              = module.eks.cluster_id
}

data "aws_eks_cluster_auth" "blur_cluster" {
  name                              = module.eks.cluster_id
}

data "aws_availability_zones" "available" {}