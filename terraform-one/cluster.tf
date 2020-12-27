

data "aws_availability_zones" "available_zones" {}

# -- Resources required for the master setup --

# The actual master node
resource "aws_eks_cluster" "blur-cluster" {
    name = var.cluster-name
    # Attaches the IAM role created above.
    role_arn = aws_iam_role.blur-iam-role.arn

    vpc_config {
        # Attaches the security group created for the master.
        # Attaches also the subnets.
        security_group_ids  = [aws_security_group.blur-cluster.id]
        subnet_ids          = aws_subnet.subnet.*.id
    }

    depends_on = [ 
        aws_iam_role_policy_attachment.blur-iam-role-AmazonEKSClusterPolicy,
        
     ]
}

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
    role        = aws_iam_role.blur-iam-role.name
  
}

# Master security group

# # A security group acts as a virtual firewall to control inbound and outbound traffic.
# This security group will control networking access to the K8S master.
resource "aws_security_group" "blur-cluster" {
    name            = "eks-blur-cluster"
    description     = "Allows the communucation with the worker nodes"
    vpc_id          = aws_vpc.blur-vpc.id

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

locals {
    node-user-data =<<USERDATA
#!/bin/bash
set -o xtrace
/etc/eks/bootstrap.sh --apiserver-endpoint '${aws_eks_cluster.blur-cluster.endpoint}'
USERDATA
}
