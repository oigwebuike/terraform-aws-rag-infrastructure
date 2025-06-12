# examples/existing-vpc/main.tf
terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = "us-east-1"
}

# Use existing VPC and subnets
data "aws_vpc" "existing" {
  id = var.vpc_id
}

data "aws_subnets" "private" {
  filter {
    name   = "vpc-id"
    values = [var.vpc_id]
  }
  
  tags = {
    Type = "Private"
  }
}

module "rag_infrastructure" {
  source = "../../"
  
  name_prefix = "existing-vpc-rag"
  
  # Use existing VPC
  vpc_id     = data.aws_vpc.existing.id
  subnet_ids = data.aws_subnets.private.ids
  
  # Production-grade settings
  db_instance_class       = "db.r6g.xlarge"
  deletion_protection     = true
  backup_retention_period = 30
  
  enable_performance_insights = true
  enable_enhanced_monitoring  = true
  
  tags = {
    Environment = "production"
    Project     = "enterprise-rag"
    VPC         = "existing"
  }
}