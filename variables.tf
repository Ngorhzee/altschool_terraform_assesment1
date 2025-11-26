variable "cidr" {
default = "10.0.0.0/16"
type =  string  
}
variable "public_cidr" {
default = "0.0.0.0/0"
description = "to allow internet access"
type =  string  
}

variable "vpc_tag" {
  type = string
  default = "techcorp-vpc"
}
variable "igw_tag" {
  type = string
  default = "techcorp-igw"
}

variable "t3_mirco" {
  type = string
  default = "t3.micro"
}
variable "t3_small" {
  type = string
  default = "t3.small"
}
variable "ssh_port" {
  type = number
  default = 22
}
variable "http_port" {
  type = number
  default = 80
}
variable "https_port" {
  type = number
  default = 443
}
variable "mysql_port" {
  type = number
  default = 3306
}

variable "public_subnets" {
  type = map(number)
  default = {
    techcorp-public-subnet-1 = 1
    techcorp-public-subnet-2 = 2
  }
  
}
variable "private_subnets" {
  type = map(number)
  default = {
    techcorp-private-subnet-1 = 1
    techcorp-private-subnet-2 = 2
  }
  
}

variable "ssh_username" {
  description = "SSH username"
  type        = string
  default     = "techcorpuser"
}

variable "my_ip" {
  description = "My IP address for SSH access"
  type        = string
  
}
variable "key_pair_name" {
  description = "Key pair name for SSH access"
  type        = string
  
}

variable "ssh_password" {
  description = "SSH password"
  type        = string
  sensitive   = true
}