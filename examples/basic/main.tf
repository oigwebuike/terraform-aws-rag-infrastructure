# examples/basic/main.tf
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
  region = var.aws_region
}

module "rag_infrastructure" {
  source = "../../"
  
  name_prefix = var.name_prefix
  
  # Test configuration - minimal costs
  db_instance_class = "db.t3.micro"
  deletion_protection = false
  
  tags = {
    Environment = "test"
    Project     = "rag-module-test"
    Purpose     = "basic-functionality-test"
  }
}

resource "random_id" "test_suffix" {
  byte_length = 4
}