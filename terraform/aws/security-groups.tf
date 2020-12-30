## Not required. Without it, a default security groups will be used.
resource "aws_security_group" "security_group" {
  name_prefix       = "sec_group_worker"
  vpc_id            = module.vpc.vpc_id

  ingress {
    from_port       = 22
    to_port         = 22
    protocol        = "tcp"

    cidr_blocks     = [
      "10.0.0.0/8",
    ]
  }
}