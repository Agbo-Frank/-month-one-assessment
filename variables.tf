variable "instance_type" {
  description = "The size of the EC2 instance"
  type        = string
  default     = "t3.micro"
}

variable "region" {
  description = "The size of the EC2 instance"
  type        = string
  default     = "us-east-1"
}

variable "title" {
  description = "The size of the EC2 instance"
  type        = string
  default     = "techcorp"
}

variable "deployer_public_key" {
  type = string
}