data "aws_availability_zones" "available" {}
data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]
  filter {
    name   = "architecture"
    values = ["arm64"]
  }
  filter {
    name   = "name"
    values = ["al2023-ami-2023*"]
  }
}


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
  cidr_block = cidrsubnet(var.cidr,8,each.value)
  availability_zone = tolist(data.aws_availability_zones.available.names)[each.value]
  tags = {
    names = each.key
  }
}

resource "aws_subnet" "private_subnets" {
  for_each = var.private_subnets
  vpc_id = aws_vpc.techcorp_vpc.id
  cidr_block = cidrsubnet(var.cidr,8,each.value+2)
  availability_zone = tolist(data.aws_availability_zones.available.names)[each.value]
  tags = {
    names = each.key
  }
}

resource "aws_internet_gateway" "techcorp_igw" {
  vpc_id = aws_vpc.techcorp_vpc.id
  tags = {
    Name = "techcorp-igw"
  }
  
}

resource "aws_eip" "techcorp_nat_eip" {
  for_each = aws_subnet.public_subnets
  depends_on = [ aws_internet_gateway.techcorp_igw ]
  tags = {
    Name = "techcorp-eip-${each.key}"
  }
  
}
resource "aws_nat_gateway" "techcorp_nat_gw" {
  depends_on = [ aws_internet_gateway.techcorp_igw ]
  for_each = aws_subnet.public_subnets
  subnet_id = each.value.id
  allocation_id = aws_eip.techcorp_nat_eip[each.key].id
  tags = {
    Name = "techcorp-nat-${each.key}"
  }
  
}

resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.techcorp_vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.techcorp_igw.id
  }
tags = {
  Name = "public_route_table"
}
}
resource "aws_route_table_association" "public_rt_assoc" {
  route_table_id = aws_route_table.public_rt[each.key].id
  depends_on = [ aws_subnet.public_subnets]
  for_each = aws_subnet.public_subnets
  subnet_id = each.value.id
}

resource "aws_route_table_association" "private_rt_assoc" {
  route_table_id = aws_route_table.private_rt[each.key].id
  depends_on = [ aws_subnet.private_subnets]
  for_each = aws_subnet.private_subnets
  subnet_id = each.value.id
}
resource "aws_route_table" "private_rt" {
  vpc_id = aws_vpc.techcorp_vpc.id
for_each = aws_nat_gateway.techcorp_nat_gw
  route {
    cidr_block = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.techcorp_nat_gw[each.key].id
  }
tags = {
  Name = "private_route_table"
}
}

resource "aws_security_group" "bastion_sg" {
  name        = "bastion-sg"
  description = "Security group for bastion host"
  ingress{
    from_port = 22
    to_port = 22
    protocol = "tcp"

  }
  vpc_id      = aws_vpc.techcorp_vpc.id
}

resource "aws_security_group" "web_server_sg" {
  name        = "web-server-sg"
  description = "Allow HTTP and SSH traffic"
  vpc_id      = aws_vpc.techcorp_vpc.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
}
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
}

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    security_groups = [aws_security_group.bastion_sg.id]
  }
   egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
   Name = "web_server_sg"
  }
}

resource "aws_security_group" "database_sg" {
  name = "database_sg"
  description = "Allow MySQL (3306) only from web security group Allow SSH(22) from Bastion Security Group"
  ingress{
    from_port = 3306
    to_port = 3306
    protocol = "tcp"
    security_groups = [aws_security_group.web_server_sg.id]
  }
  ingress {
    from_port = 22
    to_port = 22
    protocol = "tcp"
    security_groups = [aws_security_group.bastion_sg.id]
  }
  
}

resource "aws_instance" "baston_host" {
  ami = data.aws_ami.amazon_linux.id
  instance_type = "t3.mirco"
  associate_public_ip_address = true
  subnet_id = aws_subnet.public_subnets["techcorp-public-subnet-1"].id
  tags = {
    Name = "baston_host"
  }
  
}
resource "aws_instance" "web_server" {
  for_each = aws_subnet.private_subnets
  ami = data.aws_ami.amazon_linux.id
  instance_type = "t3.mirco"
  subnet_id = each.value.id
  tags = {
    Name = "web_server${each.key}"
  }
}
resource "aws_instance" "database_server" {
  ami = data.aws_ami.amazon_linux.id
  instance_type = "t3.small"
  subnet_id = aws_subnet.private_subnets["techcorp-private-subnet-1"].id
  tags = {
    Name = "database_server"
  }
}