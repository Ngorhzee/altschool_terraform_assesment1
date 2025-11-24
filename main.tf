data "aws_availability_zones" "available" {}
resource "aws_vpc" "techcorp_vpc" {
  cidr_block = var.cidr
  tags = {
    Name = var.vpc_tag
  }
  enable_dns_hostnames = true
  enable_dns_support = true
}

resource "aws_subnet" "public_subnets" {
  for_each = var.public_subnets
  vpc_id = aws_vpc.techcorp_vpc.id
  cidr_block = cidrsubnet()
  availability_zone = tolist(data.aws_availability_zones.available.names)[each.value]
  tags = {
    names = each.key
  }
}

resource "aws_subnet" "private_subnets" {
  for_each = var.private_subnets
  vpc_id = aws_vpc.techcorp_vpc.id
  cidr_block = cidrsubnet()
  availability_zone = tolist(data.aws_availability_zones.available.names)[each.value]
  tags = {
    names = each.key
  }
}