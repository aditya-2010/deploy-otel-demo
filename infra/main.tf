terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  backend "s3" {
    bucket         = "hms-state-tf"
    key            = "eks/terraform.tfstate"
    region         = "ap-south-1"
    dynamodb_table = "terraform-lock"
    encrypt        = true
  }
}

provider "aws" {
  region = "ap-southeast-1"
}

# Get available AZs
data "aws_availability_zones" "available" {
  state = "available"
}

module "vpc" {
  source               = "./modules/vpc"
  vpc_cidr             = "20.0.0.0/16"
  cluster_name         = "otel-demo-cluster"
  availability_zones   = data.aws_availability_zones.available.names
  public_subnet_cidrs  = ["20.0.1.0/24", "20.0.2.0/24", "20.0.5.0/24"]
  private_subnet_cidrs = ["20.0.3.0/24", "20.0.4.0/24", "20.0.6.0/24"]
}

module "eks" {
  source          = "./modules/eks"
  cluster_name    = "otel-demo-cluster"
  cluster_version = "1.33"
  subnet_ids      = module.vpc.private_subnet_ids
  node_groups = {
    general = {
      instance_types = ["t3.medium"]
      capacity_type  = "ON_DEMAND"
      scaling_config = {
        desired_size = 2
        max_size     = 4
        min_size     = 1
      }
    }
  }
}
