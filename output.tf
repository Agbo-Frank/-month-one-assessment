output "vpc_id" {
  description = "The ID of the VPC"
  value       = aws_vpc.main.id
}

output "lb_id" {
  description = "The DNS name of the application load balancer"
  value       = aws_lb.main.dns_name
}

output "bastion_public_ip" {
  description = "The public IP address of the bastion host"
  value       = aws_instance.bastion.public_ip
}