# 🚀 TechCorp Infrastructure Deployment
Infrastructure-as-Code using Terraform

This repository contains Terraform configurations for deploying TechCorp’s highly available, secure, and scalable cloud infrastructure. The setup follows industry best practices and meets all business requirements, including multi‑AZ availability, network isolation, load balancing, and secure admin access.

---

## 📌 Architecture Overview

The infrastructure provisions the following:

### Networking
- VPC with **public and private subnets** across multiple availability zones  
- Internet Gateway (for public subnets)  
- NAT Gateway (for private instances outbound access)  
- Route tables for proper traffic flow  
- Secure network isolation between layers  

### Compute
- Auto Scaling Group (ASG) hosting web application servers  
- EC2 Launch Template for consistent configuration  
- Instances deployed in **multiple AZs** for high availability  

### Bastion Host
- Deployed in public subnet  
- Provides secure SSH access to private EC2 instances  
- Restricted via security groups  

### Load Balancing
- Application Load Balancer (ALB)  
- Distributes traffic across EC2 instances in the ASG  
- Health checks for fault tolerance  

### Security
- Security groups with least-privilege rules  
- Encrypted storage (EBS)  
- Restricted SSH access only via Bastion host  
- No direct internet access to private instances  

---

## 🖼 Architecture Diagram

```
           Internet
               |
        +----------------+
        |   ALB (Public) |
        +----------------+
          /          \
         /            \
+---------------+  +---------------+
|  Public Subnet|  |  Public Subnet|
| Bastion Host  |  |   NAT GW      |
+---------------+  +---------------+
         |                |
         |                |
   +----------------------------+
   |     Private Subnets (AZ1/2)|
   | +------------------------+ |
   | | EC2 ASG (Web Servers)  | |
   | +------------------------+ |
   +----------------------------+
```

---

## 🧰 Prerequisites

### Local Requirements
- **Terraform v1.6+**  
- **AWS CLI v2+**  
- A configured AWS profile:
```bash
aws configure
```
- SSH key pair created in AWS or locally:
```bash
ssh-keygen -t rsa -b 4096 -f ~/.ssh/techcorp-key
```

### AWS Requirements
IAM user with permissions for:
- VPC, EC2, ELB, Auto Scaling  
- S3 (if using remote backend)  
- IAM roles (if Terraform creates instance roles)  

---

## 🚀 Deployment Steps

### 1. Clone the Repository
```bash
git clone https://github.com/your-repo/techcorp-infra.git
cd techcorp-infra
```

### 2. Initialize Terraform
```bash
terraform init
```

### 3. Validate Configuration (Optional)
```bash
terraform validate
```

### 4. Deploy Infrastructure
```bash
terraform apply
```
Type **yes** when prompted.  
Terraform will create:
- VPC, subnets, NAT, routing  
- Bastion host  
- Load balancer  
- Auto Scaling group  
- EC2 instances  
- Security groups  

### 5. Access the Application
Terraform outputs:
- **ALB DNS name** → access web app  
- **Bastion Host Public IP** → SSH access
```bash
ssh -i ~/.ssh/techcorp-key ec2-user@<bastion-ip>
```
From the bastion, SSH into private EC2 instances.

---

## 🧹 Cleanup Instructions

### 1. Destroy All Resources
```bash
terraform destroy
```
Type **yes** when prompted.

### 2. Verify Cleanup
Check that the following are removed:
- EC2 instances  
- Load balancer  
- NAT gateways  
- Auto Scaling groups  
- VPC  

---

## 📂 Repository Structure
```
├── main.tf
├── variables.tf
├── outputs.tf
├── vpc/
│   ├── vpc.tf
│   ├── subnets.tf
│   ├── routes.tf
│   └── ...
└── compute/
    ├── asg.tf
    ├── launch_template.tf
    └── ...
```

---

## 📝 Notes
- Modular design allows easy expansion (RDS, Redis, WAF, etc.)  
- Multi-AZ deployment ensures high availability and scalability  
- All resources are tagged for cost tracking and visibility

