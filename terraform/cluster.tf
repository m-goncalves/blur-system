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

resource "aws_subnet" "demo" {
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
    subnet_id       = "${aws_subnet.demo.*.id[count.index]}"
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
    description     = "Allows the communucation with worker nodes"
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

resource "aws_eks_cluster" "blur-cluster" {
    name = "${var.cluster-name}"
    role_arn = "${aws_iam_role.blur-iam-role.arn}"

    vpc_config {
        security_group_ids  = ["${aws_security_group.blur-cluster.id}"]
        subnet_ids          = "${aws_subnet.demo.*.id}"
    }

    depends_on = [ 
        "aws_iam_role_policy_attachment.blur-iam-role-AmazonEKSClusterPolicy",
        "aws_iam_role_policy_attachment.blur-iam-role-AmazonEKSClusterPolicy"
     ]
}
