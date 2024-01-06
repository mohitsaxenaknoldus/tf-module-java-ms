# Terraform module to host a Java microservice on AWS ECS

This module will create a bunch of AWS services:

1. ECR to host the images.
2. ECS cluster that will run containers through Fargate.
3. API Gateway with stages that will take the incoming requests and forward them to the service through the VPC link.
4. VPC with 4 subnets, IGW, NAT, etc.
5. Other supporting IAM and CloudWatch components.

This is using Terraform Cloud as the backend.

## How To Run?

1. Create your custom `terraform.tfvars` file if you wish to override the default values.
2. Run:
```
terraform init
terraform plan
terraform apply
```
