# TechCorp AWS Infrastructure

Terraform configuration that provisions a high-availability web application infrastructure on AWS, including a VPC, public/private subnets, NAT gateways, a bastion host, web servers, a database server, and an application load balancer.

## Architecture

- **VPC** with public and private subnets across 2 availability zones
- **Bastion host** in a public subnet for secure SSH access
- **2 Web servers** in private subnets behind an Application Load Balancer
- **1 Database server** (PostgreSQL) in a private subnet
- **NAT Gateways** in each public subnet for outbound internet access from private subnets

## Prerequisites

- [Terraform](https://developer.hashicorp.com/terraform/install) >= 1.0
- [AWS CLI](https://aws.amazon.com/cli/) configured with appropriate credentials (`aws configure`)
- An SSH key pair on your local machine

## Deployment

1. **Clone the repository and navigate to the terraform directory:**

   ```bash
   cd terraform
   ```

2. **Create your variables file:**

   ```bash
   cp terraform.tfvars.example terraform.tfvars
   ```

   Edit `terraform.tfvars` and fill in your values — particularly `deployer_public_key` and `current_ip`.

3. **Initialise Terraform:**

   ```bash
   terraform init
   ```

4. **Preview the changes:**

   ```bash
   terraform plan
   ```

5. **Apply the configuration:**

   ```bash
   terraform apply
   ```

   Type `yes` when prompted. Once complete, Terraform will output the VPC ID, load balancer DNS name, and bastion public IP.

6. **Access the application:**

   Open the load balancer DNS name from the output in your browser.

7. **SSH into the bastion:**

   ```bash
   ssh -i ~/.ssh/your-private-key ec2-user@<bastion_public_ip>
   ```

## Cleanup

To destroy all provisioned resources:

```bash
terraform destroy
```

Type `yes` when prompted. Note that `enable_deletion_protection` is set on the load balancer — you may need to disable it manually in the AWS console or set it to `false` in `main.tf` before destroying.
