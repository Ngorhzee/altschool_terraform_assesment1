variable "cidr" {
default = "10.0.0.0/16"
type =  string  
}

variable "vpc_tag" {
  default = "techcorp-vpc"
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