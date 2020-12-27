provider "aws" {
    region = "${var.AWS_REGION}"
    secret_key = "${var.AWS_SECRET_KEY}"
    access_key = "${var.AWS_ACCESS_KEY}"
  
}

# ----- Base VPC Networking -----

data "aws_availability_zones" "available_zones" {}

# Creates a virtual private network which will isolate
# the resources to be created.
resource "aws_vpc" "blur-vpc" {
    #Specifies the range of IP adresses for the VPC.
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

# The component that allows communication between 
# the VPC and the internet.
resource "aws_internet_gateway" "gateway" {
    # Attaches the gateway to the VPC.
    vpc_id = "${aws_vpc.blur-vpc.id}"

    tags = {
        Name = "eks-gateway"
    }
}

# Determines where network traffic from the gateway
# will be directed. 
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

# -- Resources required for the master setup --

# This bellow block (IAM role + Policy) allows the EKS service to 
# manage or retrieve data from other AWS services.

# Similar to a IAM but not uniquely associated with one person.
# A role can be assumed by anyone who needs it.
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

# Attaches the policy "AmazonEKSClusterPolicy" to the role created above. 
resource "aws_iam_role_policy_attachment" "blur-iam-role-AmazonEKSClusterPolicy" {
    policy_arn  = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
    role        = "${aws_iam_role.blur-iam-role.name}"
  
}

# Attaches the policy "AmazonEKSServicePolicy" to the role created above. 
# resource "aws_iam_role_policy_attachment" "blur-iam-role-AmazonEKSServicePolicy" {
#     policy_arn  = "arn:aws:iam::aws:policy/AmazonEKSServicePolicy"
#     role        = "${aws_iam_role.blur-iam-role.name}"
# }

# Master security group

# # A security group acts as a virtual firewall to control inbound and outbound traffic.
# This security group will control networking access to the K8S master.
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

# The actual master node
resource "aws_eks_cluster" "blur-cluster" {
    name = "${var.cluster-name}"
    # Attaches the IAM role created above.
    role_arn = "${aws_iam_role.blur-iam-role.arn}"

    vpc_config {
        # Attaches the security group created for the master.
        # Attaches also the subnets.
        security_group_ids  = ["${aws_security_group.blur-cluster.id}"]
        subnet_ids          = "${aws_subnet.subnet.*.id}"
    }

    depends_on = [ 
        "aws_iam_role_policy_attachment.blur-iam-role-AmazonEKSClusterPolicy",
        # "aws_iam_role_policy_attachment.blur-iam-role-AmazonEKSServicePolicy"
     ]
}

# -- Resources required for the worker nodes setup --

# IAM role for the workers. Allows worker nodes to manage or retrieve data
# from other services and  its required for the workers to join the cluster.
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

# allows Amazon EKS worker nodes to connect to Amazon EKS Clusters.
resource "aws_iam_role_policy_attachment" "iam-role-worker-AmazonEKSWorkerNodePolicy" {
    policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
    role = "${aws_iam_role.iam-role-worker.name}"
}

# This permission is required to modify the IP address configuration of worker nodes
resource "aws_iam_role_policy_attachment" "iam-role-worker-AmazonEKS_CNI_Policy" {
    policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
    role = "${aws_iam_role.iam-role-worker.name}"
}

# Allows to list repositories and pull images
resource "aws_iam_role_policy_attachment" "iam-role-worker-AmazonEC2ContainerRegistryReadOnly" {
    policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
    role = "${aws_iam_role.iam-role-worker.name}"

}

# An instance profile represents an EC2 instances (Who am I?)
# and assumes a role (what can I do?).
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

# --- Worker autoscaling group ---
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

# To spin up an auto scaling group an "aws_launch_configuration" is needed. 
# This ALC requires an "image_id" as well as a "security_group".
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

# Actual autoscaling group
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