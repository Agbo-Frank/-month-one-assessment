output "vpc_id" {
  description = "ID of the EC2 instance"
  value       = aws_vpc.main.id
}

output "lb_id" {
  description = "ID of the EC2 instance"
  value       = aws_lb.main.dns_name
}

output "bastion_public_ip" {
  description = "ID of the EC2 instance"
  value       = aws_instance.bastion.public_ip
}