data "aws_eks_cluster" "blur_cluster" {
  name = module.eks.cluster_id
}

data "aws_eks_cluster_auth" "blur_cluster" {
  name = module.eks.cluster_id
}

data "aws_availability_zones" "available" {
}