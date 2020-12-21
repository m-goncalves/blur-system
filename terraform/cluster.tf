provider "aws" {
    region = "${var.AWS_REGION}"
    secret_key = "${var.AWS_SECRET_KEY}"
    access_key = "${var.AWS_ACCESS_KEY}"
  
}

data "aws_availability_zones" "available_zones" {}

resource "aws_vpc" "blur-vpc" {
    cidr_block = "10.0.0.0/16"
    tags = "${
        map(
            "Name", "terraform-eks-node",
            "kubernetes.io/cluster/${var.cluster-name}", "shared"
        )
    }"
}

resource "aws_subnet" "subnet" {
  count = 2

  availability_zone = "${data.aws_availability_zones.available_zones.names[count.index]}"
  cidr_block        = "10.0.${count.index}.0/24"
  vpc_id            = "${aws_vpc.blur-vpc.id}"

  tags = "${
    map(
     "Name", "blur-subnet",
     "kubernetes.io/cluster/${var.cluster-name}", "shared",
    )
  }"
}

resource "aws_internet_gateway" "gateway" {
    vpc_id = "${aws_vpc.blur-vpc.id}"

    tags = {
        Name = "eks-gateway"
    }
}

resource "aws_route_table" "route-table" {
  vpc_id = "${aws_vpc.blur-vpc.id}"

  route {
      cidr_block = "0.0.0.0/0"
      gateway_id = "${aws_internet_gateway.gateway.id}"
  }
}

resource "aws_route_table_association" "table_association" {
    count = 2
    subnet_id       = "${aws_subnet.subnet.*.id[count.index]}"
    route_table_id  = "${aws_route_table.route-table.id}"
  
}

resource "aws_iam_role" "blur-iam-role" {
  name = "eks-cluster"
  assume_role_policy = <<POLICY
{
      "Version": "2012-10-17",
      "Statement": [
          {
              "Effect": "Allow",
              "Principal": {
                "Service": "eks.amazonaws.com"
            },
              "Action": "sts:AssumeRole"
        }
    ]
}
  POLICY
}

resource "aws_iam_role_policy_attachment" "blur-iam-role-AmazonEKSClusterPolicy" {
    policy_arn  = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
    role        = "${aws_iam_role.blur-iam-role.name}"
  
}

resource "aws_security_group" "blur-cluster" {
    name            = "eks-blur-cluster"
    description     = "Allows the communucation with the worker nodes"
    vpc_id          = "${aws_vpc.blur-vpc.id}"

    egress {
        from_port = 0
        to_port = 0
        protocol = "-1"
        cidr_blocks = ["0.0.0.0/0"]
    }

    tags = {
        Name = "blur-cluster"
    }
}

# resource "aws_security_group_rule" "blur-cluster-ingress-workstation" {
#     cidr_blocks             = ["A.B.C.D/32"]
#     description             = "Allow workstation to communicate with the cluster API server"
#     from_port               = 443
#     to_port                 = 443
#     protocol                = "tcp"
#     security_group_id       = "${aws_security_group.blur-cluster.id}"
#     type                    = "ingress"
# }

# Master node
resource "aws_eks_cluster" "blur-cluster" {
    name = "${var.cluster-name}"
    role_arn = "${aws_iam_role.blur-iam-role.arn}"

    vpc_config {
        security_group_ids  = ["${aws_security_group.blur-cluster.id}"]
        subnet_ids          = "${aws_subnet.subnet.*.id}"
    }

    depends_on = [ 
        "aws_iam_role_policy_attachment.blur-iam-role-AmazonEKSClusterPolicy",
        "aws_iam_role_policy_attachment.blur-iam-role-AmazonEKSClusterPolicy"
     ]
}

### worker nodes

resource "aws_iam_role" "iam-role-worker"{
    name = "eks-worker"
    assume_role_policy = <<POLICY
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Principal": {
                "Service": "ec2.amazonaws.com"
            },
            "Action": "sts:AssumeRole"
        }
    ]
}
POLICY
}

resource "aws_iam_role_policy_attachment" "iam-role-worker-AmazonEKSWorkerNodePolicy" {
    policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
    role = "${aws_iam_role.iam-role-worker.name}"
}

resource "aws_iam_role_policy_attachment" "iam-role-worker-AmazonEKS_CNI_Policy" {
    policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
    role = "${aws_iam_role.iam-role-worker.name}"
}

resource "aws_iam_role_policy_attachment" "iam-role-worker-AmazonEC2ContainerRegistryReadOnly" {
    policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
    role = "${aws_iam_role.iam-role-worker.name}"

}

resource "aws_iam_instance_profile" "worker-node" {
    name = "worker-node"
    role = "${aws_iam_role.iam-role-worker.name}"
}

# Security group for the worker nodes

resource "aws_security_group" "security-group-worker" {
    name = "worker-node"
    description = "Security group for worker nodes"
    vpc_id = "${aws_vpc.blur-vpc.id}"
    egress {
        cidr_blocks = [ "0.0.0.0/0" ]
        from_port = 0
        to_port = 0
        protocol = "-1"
    }

    tags = "${
      map(
          "Name", "blur-cluster",
          "kubernetes.io/cluster/${var.cluster-name}", "owned"
      )
    }"
}

resource "aws_security_group_rule" "ingress-self" {
    description = "Allow communication among nodes"
    from_port = 0
    to_port = 65535
    protocol = "-1"
    security_group_id = "${aws_security_group.security-group-worker.id}"
    source_security_group_id = "${aws_security_group.security-group-worker.id}"
    type = "ingress"
}

resource "aws_security_group_rule" "ingress-cluster-https" {
    description = "Allow worker to receive communication from the cluster control plane"
    from_port = 443
    to_port = 443
    protocol = "tcp"
    security_group_id = "${aws_security_group.security-group-worker.id}"
    source_security_group_id = "${aws_security_group.blur-cluster.id}"
    type = "ingress"
    
}

resource "aws_security_group_rule" "ingress-cluster-others" {
    description = "Allow worker to receive communication from the cluster control plane"
    from_port = 1025
    to_port = 65535
    protocol = "tcp"
    security_group_id = "${aws_security_group.security-group-worker.id}"
    source_security_group_id = "${aws_security_group.blur-cluster.id}"
    type = "ingress"
}

# Worker Access to Master

resource "aws_security_group_rule" "cluster-node-ingress-http" {
    description                     = "Allows pods to communicate with the cluster API server"
    from_port                       = 443
    to_port                         = "443"
    protocol                        = "tcp"
    security_group_id               = "${aws_security_group.blur-cluster.id}"
    source_security_group_id        = "${aws_security_group.security-group-worker.id}"
    type                            = "ingress"
  
}

# Worker autoscaling group

# This data will be used to filter and select an AMI which is compatible with the specific k8s version being deployed
data "aws_ami" "eks-worker" {
    filter {
      name = "name"
      values = ["amazon-eks-node-${aws_eks_cluster.blur-cluster.version}-v*"]
    }

    most_recent = true
    owners = ["602401143452"] 
}

data "aws_region" "current" {}

locals {
    node-user-data =<<USERDATA
#!/bin/bash
set -o xtrace
/etc/eks/bootstrap.sh --apiserver-endpoint '${aws_eks_cluster.blur-cluster.endpoint}'
USERDATA
}

resource "aws_launch_configuration" "launch_config" {
    associate_public_ip_address     = true
    iam_instance_profile        = "${aws_iam_instance_profile.worker-node.name}"
    image_id                    = "${data.aws_ami.eks-worker.id}"
    instance_type               = "t2.micro"
    name_prefix                 = "terraform-eks"
    security_groups             = ["${aws_security_group.security-group-worker.id}"]
    user_data_base64            = "${base64encode(local.node-user-data)}"
    lifecycle {
      create_before_destroy     = true
    }
  
}

# Autoscaling group

resource "aws_autoscaling_group" "autoscaling" {
    desired_capacity = 2
    launch_configuration        = "${aws_launch_configuration.launch_config.id}" 
    max_size                    = 2
    min_size                    = 1
    name                        = "terraform-eks"
    vpc_zone_identifier         = "${aws_subnet.subnet.*.id}"

    tag {
      key = "Name"
      value = "terraform-eks"
      propagate_at_launch = true
    }

# "kubernetes.io/cluster/*" tag allows EKS and K8S to discover and manage compute resources.
    tag {
      key                       = "kubernetes.io/cluster/${var.cluster-name}"
      value                     = "owned"
      propagate_at_launch       = true
    }
}