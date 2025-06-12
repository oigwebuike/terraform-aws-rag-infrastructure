# examples/complete/main.tf
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

# Data sources
data "aws_availability_zones" "available" {
  state = "available"
}

module "rag_infrastructure" {
  source = "../../"
  
  name_prefix = var.name_prefix
  
  # S3 Configuration
  bucket_name       = "${var.name_prefix}-documents-${random_id.bucket_suffix.hex}"
  enable_versioning = true
  
  # Network Configuration - Create new VPC
  vpc_cidr           = "10.0.0.0/16"
  availability_zones = slice(data.aws_availability_zones.available.names, 0, 2)
  
  # Database Configuration
  postgres_version            = "15.7"
  db_instance_class          = var.environment == "production" ? "db.r6g.large" : "db.t3.small"
  db_allocated_storage       = var.environment == "production" ? 100 : 20
  db_max_allocated_storage   = var.environment == "production" ? 1000 : 100
  backup_retention_period    = var.environment == "production" ? 30 : 7
  deletion_protection        = var.environment == "production"
  enable_performance_insights = var.environment == "production"
  enable_enhanced_monitoring = var.environment == "production"
  
  # AI Model Configuration
  embedding_model       = "amazon.titan-embed-text-v1"
  text_generation_model = "anthropic.claude-3-sonnet-20240229-v1:0"
  enable_bedrock_access = true
  
  # Application Configuration
  application_service_principal = "lambda.amazonaws.com"
  
  tags = merge(var.common_tags, {
    Environment = var.environment
    Project     = "complete-rag-example"
  })
}

resource "random_id" "bucket_suffix" {
  byte_length = 4
}