variable "web_instance_type" {
  description = "The EC2 instance type to use for all servers"
  type        = string
  default     = "t3.micro"
}

variable "db_instance_type" {
  description = "The EC2 instance type to use for all servers"
  type        = string
  default     = "t3.small"
}

variable "region" {
  description = "The AWS region to deploy resources into"
  type        = string
  default     = "us-east-1"
}

variable "title" {
  description = "A name prefix applied to all resource tags for identification"
  type        = string
  default     = "techcorp"
}

variable "key_pair_name" {
  description = "The name of the EC2 key pair to create and associate with instances"
  type        = string
  default     = "deployer-key"
}

variable "deployer_public_key" {
  description = "The public SSH key used to create the EC2 key pair for instance access"
  type        = string
  sensitive   = true
}

variable "current_ip" {
  description = "Your current public IP address in CIDR notation (e.g. 102.0.0.1/32) used to restrict SSH access to the bastion host"
  type        = string
  default = "0.0.0.0/0"
}