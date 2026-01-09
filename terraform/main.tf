provider "aws" {
  region = var.region
}

data "aws_availability_zones" "available" {}

# VPC
module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "6.6.0"

  name             = "cobank-vpc"
  cidr             = "10.0.0.0/16"
  azs              = slice(data.aws_availability_zones.available.names, 0, 3)
  private_subnets  = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
  public_subnets   = ["10.0.101.0/24", "10.0.102.0/24", "10.0.103.0/24"]
  enable_nat_gateway = true
  single_nat_gateway = true
}

# EKS v18
module "eks" {
  source          = "terraform-aws-modules/eks/aws"
  version         = "18.29.3"

  cluster_name    = var.cluster_name
  cluster_version = "1.27"
  vpc_id          = module.vpc.vpc_id
  subnets         = module.vpc.private_subnets

  # Node groups (v18 syntax)
  node_groups = {
    default = {
      desired_capacity = var.node_desired_capacity
      min_capacity     = var.node_min_size
      max_capacity     = var.node_max_size
      instance_type    = var.node_instance_type
    }
  }

  manage_aws_auth = true
}
