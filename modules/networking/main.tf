variable "ingressports" {
  type    = list(number)
  default = [8080, 22]
}

// TODO break public and private into separate AZs
data "aws_availability_zones" "available" {}

module "vpc" {
  source = "terraform-aws-modules/vpc/aws"
  name                             = "${var.namespace}-vpc"
  cidr                             = "10.0.0.0/16"
  azs                              = data.aws_availability_zones.available.names
#  private_subnets                  = ["10.0.1.0/24", "10.0.2.0/24"]
  public_subnets                   = ["10.0.101.0/24", "10.0.102.0/24"]
  #assign_generated_ipv6_cidr_block = true
  create_database_subnet_group     = true
  enable_nat_gateway               = false
  single_nat_gateway               = false
}

// SG to allow SSH connections from anywhere
resource "aws_security_group" "allow_ssh_pub" {
  name        = "${var.namespace}-allow_ssh"
  description = "Allow SSH inbound traffic"
  vpc_id      = module.vpc.vpc_id

  dynamic "ingress" {
    for_each = var.ingressports
    content {
      protocol    = "tcp"
      from_port   = ingress.value
      to_port     = ingress.value
      cidr_blocks = ["0.0.0.0/0"]
    }
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.namespace}-allow_ssh_pub"
  }
}
