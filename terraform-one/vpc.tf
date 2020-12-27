# ----- Base VPC Networking -----

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
  availability_zone = data.aws_availability_zones.available_zones.names[count.index]
  cidr_block        = "10.0.${count.index}.0/24"
  vpc_id            = aws_vpc.blur-vpc.id

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
    vpc_id = aws_vpc.blur-vpc.id

    tags = {
        Name = "eks-gateway"
    }
}

# Determines where network traffic from the gateway
# will be directed to. 
resource "aws_route_table" "route-table" {
  vpc_id = aws_vpc.blur-vpc.id

  route {
      cidr_block = "0.0.0.0/0"
      gateway_id = aws_internet_gateway.gateway.id
  }
}

resource "aws_route_table_association" "table_association" {
    count = 2
    subnet_id       = aws_subnet.subnet.*.id[count.index]
    route_table_id  = aws_route_table.route-table.id
  
}