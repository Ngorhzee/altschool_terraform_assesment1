# Get available zones
data "aws_availability_zones" "available" {
  state = "available"
}

# Get Amazon Linux 2 image
data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]
  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]

  }
}
locals {
  private_to_public = {
    for key, value in var.private_subnets :
    key => "techcorp-public-subnet-${value}"
  }
}

# 1. CREATE VPC
resource "aws_vpc" "main" {
  cidr_block = var.cidr
  tags = {
    Name = var.vpc_tag
  }
  enable_dns_hostnames = true
  enable_dns_support   = true
}

#2. CREATE PUBLIC SUBNETS
resource "aws_subnet" "public_subnets" {
  for_each                = var.public_subnets
  vpc_id                  = aws_vpc.main.id
  cidr_block              = cidrsubnet(var.cidr, 8, each.value)
  map_public_ip_on_launch = true
  availability_zone       = tolist(data.aws_availability_zones.available.names)[each.value]
  tags = {
    names = each.key
  }
}

#3. CREATE PRIVATE SUBNETS
resource "aws_subnet" "private_subnets" {
  for_each          = var.private_subnets
  vpc_id            = aws_vpc.main.id
  cidr_block        = cidrsubnet(var.cidr, 8, each.value + 2)
  availability_zone = tolist(data.aws_availability_zones.available.names)[each.value]
  tags = {
    names = each.key
  }
}

# 4. CREATE INTERNET GATEWAY
resource "aws_internet_gateway" "techcorp_igw" {
  vpc_id = aws_vpc.main.id
  tags = {
    Name = var.igw_tag
  }

}

# 5. CREATE ELASTIC IPS FOR NAT GATEWAYS
resource "aws_eip" "techcorp_nat_eip" {
  domain     = "vpc"
  for_each   = aws_subnet.public_subnets
  depends_on = [aws_internet_gateway.techcorp_igw]
  tags = {
    Name = "techcorp-eip-${each.key}"
  }

}

# 6. CREATE NAT GATEWAYS
resource "aws_nat_gateway" "techcorp_nat_gw" {
  depends_on    = [aws_internet_gateway.techcorp_igw]
  for_each      = aws_subnet.public_subnets
  subnet_id     = each.value.id
  allocation_id = aws_eip.techcorp_nat_eip[each.key].id
  tags = {
    Name = "techcorp-nat-${each.key}"
  }

}

# 7. CREATE  ROUTE TABLES FOR PUBLIC SUBNETS
resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.main.id
  route {
    cidr_block = var.public_cidr
    gateway_id = aws_internet_gateway.techcorp_igw.id
  }
  tags = {
    Name = "public_route_table"
  }
}

# 8. CREATE ROUTE TABLES FOR PRIVATE SUBNETS
resource "aws_route_table" "private_rt" {
  vpc_id   = aws_vpc.main.id
  for_each = aws_subnet.private_subnets
  route {
    cidr_block = var.public_cidr
    nat_gateway_id = aws_nat_gateway.techcorp_nat_gw[local.private_to_public[each.key]].id
  }
  tags = {
    Name = "private_route_table"
  }
}

# 9. CONNECT ROUTE TABLES TO SUBNETS
resource "aws_route_table_association" "public_rt_assoc" {
  route_table_id = aws_route_table.public_rt.id
  depends_on     = [aws_subnet.public_subnets]
  for_each       = aws_subnet.public_subnets
  subnet_id      = each.value.id
}

resource "aws_route_table_association" "private_rt_assoc" {
  for_each       =  aws_subnet.private_subnets
  depends_on     = [aws_subnet.private_subnets]
  route_table_id = aws_route_table.private_rt[each.key].id
  subnet_id      = each.value.id
}



# 10. CREATE BASTION SECURITY GROUP
resource "aws_security_group" "bastion_sg" {
  name        = "bastion-sg"
  description = "Security group for bastion host"
  vpc_id      = aws_vpc.main.id
  ingress {
    description = "SSH from my IP"
    from_port   = var.ssh_port
    to_port     = var.ssh_port
    protocol    = "tcp"
    cidr_blocks = [var.my_ip]
   
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = [var.public_cidr]
  }

  tags = {
    Name = "bastion-sg"
  }
}

# 11. CREATE WEBSERVER SECURITY GROUP
resource "aws_security_group" "web_server_sg" {
  name        = "web-server-sg"
  description = "Allow HTTP and SSH traffic"
  vpc_id      = aws_vpc.main.id

  ingress {
    description = "HTTP from anywhere"
    from_port   = var.http_port
    to_port     = var.http_port
    protocol    = "tcp"
    cidr_blocks = [var.public_cidr]
  }
  ingress {
    description = "HTTPS from anywhere"
    from_port   = var.https_port
    to_port     = var.https_port
    protocol    = "tcp"
    cidr_blocks = [var.public_cidr]
  }

  ingress {
    description     = "SSH from bastion"
    from_port       = var.ssh_port
    to_port         = var.ssh_port
    protocol        = "tcp"
    security_groups = [aws_security_group.bastion_sg.id]
    cidr_blocks = [var.my_ip]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = [var.public_cidr]
  }
  tags = {
    Name = "web_server_sg"
  }
}

# 11. CREATE DATABASE SECURITY GROUP
resource "aws_security_group" "database_sg" {
  name        = "database_sg"
  vpc_id = aws_vpc.main.id
  description = "Allow MySQL (3306) only from web security group Allow SSH(22) from Bastion Security Group"

  ingress {
    description     = "MySQL from web servers"
    from_port       = var.mysql_port
    to_port         = var.mysql_port
    protocol        = "tcp"
    security_groups = [aws_security_group.web_server_sg.id]
  }

  ingress {
    description     = "SSH from bastion"
    from_port       = var.ssh_port
    to_port         = var.ssh_port
    protocol        = "tcp"
    security_groups = [aws_security_group.bastion_sg.id]
    cidr_blocks = [var.my_ip]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = [var.public_cidr]
  }

}

# 13. CREATE BASTION HOST
resource "aws_instance" "baston_host" {
  ami                         = data.aws_ami.amazon_linux.id
  instance_type               = var.t3_mirco
  associate_public_ip_address = true
  key_name = var.key_pair_name
  vpc_security_group_ids = [aws_security_group.bastion_sg.id]
  subnet_id                   = aws_subnet.public_subnets["techcorp-public-subnet-1"].id
  user_data                   = <<-EOF
              #!/bin/bash
              yum update -y
              useradd -m ${var.ssh_username}
              echo "${var.ssh_username}:${var.ssh_password}" | chpasswd
              sed -i 's/PasswordAuthentication no/PasswordAuthentication yes/g' /etc/ssh/sshd_config
              systemctl restart sshd
              echo "${var.ssh_username} ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers.d/${var.ssh_username}
              EOF
  tags = {
    Name = "baston_host"
  }

}

# 14. CREATE ELASTIC IP FOR BASTION
resource "aws_eip" "bastion_eip" {
  domain     = "vpc"
  instance   = aws_instance.baston_host.id
  depends_on = [aws_internet_gateway.techcorp_igw]
 
  tags = {
    Name = "techcorp-bastion-eip"
  }
}

# 15. CREATE WEB SERVERS
resource "aws_instance" "web_server" {
  for_each      = aws_subnet.private_subnets
  vpc_security_group_ids = [aws_security_group.web_server_sg.id]
  ami           = data.aws_ami.amazon_linux.id
  instance_type = var.t3_mirco
  key_name = var.key_pair_name
  subnet_id     = each.value.id
  tags = {
    Name = "web_server${each.key}"
  }
  user_data = file("./user_data/web_serversetup.sh")
}

# 16. CREATE DATABASE SERVERS
resource "aws_instance" "database_server" {
  ami           = data.aws_ami.amazon_linux.id
  instance_type = var.t3_small
  key_name = var.key_pair_name
  vpc_security_group_ids = [aws_security_group.database_sg.id]
  subnet_id     = aws_subnet.private_subnets["techcorp-private-subnet-1"].id
  tags = {
    Name = "database_server"
  }
  user_data = file("./user_data/db_server_setup.sh")
}

# 17. CREATE LOAD BALANCER
resource "aws_alb" "load_balancer" {
  name     = "techcorp-alb"
  internal = false
  security_groups    = [aws_security_group.web_server_sg.id]
  subnets = [
    for subnet in aws_subnet.public_subnets : subnet.id
  ]
  load_balancer_type = "application"
  tags = {
    Name = "techcorp-alb"
  }
}

# 18. CREATE TARGET GROUPS
resource "aws_alb_target_group" "alb_target" {
  name        = "techcorp-web-tg"
  port        = var.http_port
  protocol    = "HTTP"
  vpc_id      = aws_vpc.main.id
  target_type = "instance"
  health_check {
    protocol            = "HTTP"
    path                = "/"
    port                = "traffic-port"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 3
    unhealthy_threshold = 2
    enabled = true
  }

}

# 19. CREATE ALB LISTENERS
resource "aws_alb_listener" "aws_alb_listener" {
  load_balancer_arn = aws_alb.load_balancer.arn
  port              = var.http_port
  protocol          = "HTTP"
  default_action {
    type             = "forward"
    target_group_arn = aws_alb_target_group.alb_target.arn
  }

}

# 20. ATTACH WEB SERVERS TO TARGET GROUP
resource "aws_lb_target_group_attachment" "tg_attachment" {
  target_group_arn = aws_alb_target_group.alb_target.arn
  for_each         = aws_instance.web_server
  target_id        = aws_instance.web_server[each.key].id
  port             = var.http_port

}
