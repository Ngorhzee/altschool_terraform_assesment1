output "vpc_id" {
  description = "VPC ID"
  value       = aws_vpc.main.id
}

output "load_balancer_dns_name" {
  description = "Load Balancer DNS"
  value       = aws_alb.load_balancer.dns_name
}

output "bastion_public_ip" {
  description = "Bastion Public IP"
  value       = aws_eip.bastion_eip.public_ip
}