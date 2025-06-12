# README.md
# AWS RAG Infrastructure Terraform Module

[![Terraform Registry](https://img.shields.io/badge/terraform-registry-blue.svg)](https://registry.terraform.io/modules/your-username/rag-infrastructure/aws)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

A comprehensive Terraform module for provisioning Retrieval-Augmented Generation (RAG) infrastructure on AWS. This module sets up the essential components needed to build and deploy RAG applications, including document storage, vector database, and AI model integration.

## 🏗️ Architecture

This module creates:

- **S3 Bucket**: Secure document storage with encryption and versioning
- **PostgreSQL RDS**: Vector database with pgvector extension support
- **VPC & Networking**: Optional isolated network environment
- **IAM Roles & Policies**: Secure access controls for applications
- **Secrets Manager**: Secure database credential storage
- **AWS Bedrock Integration**: Ready-to-use AI model access

## 🚀 Quick Start

```hcl
module "rag_infrastructure" {
  source = "your-username/rag-infrastructure/aws"
  
  name_prefix = "my-rag-app"
  
  tags = {
    Environment = "production"
    Project     = "ai-chatbot"
  }
}
```

## 📋 Requirements

| Name | Version |
|------|---------|
| terraform | >= 1.0 |
| aws | ~> 5.0 |
| random | ~> 3.1 |

## 🔧 Usage Examples

### Basic Usage

```hcl
module "rag_infrastructure" {
  source = "your-username/rag-infrastructure/aws"
  
  name_prefix = "my-rag-app"
  bucket_name = "my-unique-document-bucket"
  
  # Database configuration
  db_instance_class = "db.t3.small"
  postgres_version  = "15.7"
  
  # AI models
  embedding_model        = "amazon.titan-embed-text-v1"
  text_generation_model  = "anthropic.claude-3-sonnet-20240229-v1:0"
  
  tags = {
    Environment = "production"
    Project     = "ai-chatbot"
  }
}
```

### Using Existing VPC

```hcl
module "rag_infrastructure" {
  source = "your-username/rag-infrastructure/aws"
  
  name_prefix = "my-rag-app"
  
  # Use existing VPC
  vpc_id     = "vpc-12345678"
  subnet_ids = ["subnet-12345678", "subnet-87654321"]
  
  # Production settings
  db_instance_class       = "db.r6g.large"
  deletion_protection     = true
  backup_retention_period = 30
  
  enable_performance_insights = true
  enable_enhanced_monitoring  = true
  
  tags = {
    Environment = "production"
    Project     = "enterprise-rag"
  }
}
```

### Development Environment

```hcl
module "rag_infrastructure" {
  source = "your-username/rag-infrastructure/aws"
  
  name_prefix = "dev-rag"
  
  # Minimal resources for development
  db_instance_class     = "db.t3.micro"
  db_allocated_storage  = 20
  deletion_protection   = false
  enable_versioning     = false
  
  # Allow public access for testing (not recommended for production)
  application_service_principal = "lambda.amazonaws.com"
  
  tags = {
    Environment = "development"
    Project     = "rag-prototype"
  }
}
```

## 📊 Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| name_prefix | Prefix for all resource names | `string` | `"rag"` | no |
| bucket_name | S3 bucket name for document storage. If empty, a unique name will be generated | `string` | `""` | no |
| enable_versioning | Enable S3 bucket versioning | `bool` | `true` | no |
| vpc_id | VPC ID to deploy resources in. If empty, a new VPC will be created | `string` | `""` | no |
| vpc_cidr | CIDR block for VPC (only used if vpc_id is empty) | `string` | `"10.0.0.0/16"` | no |
| subnet_ids | List of subnet IDs for RDS (required if vpc_id is provided) | `list(string)` | `[]` | no |
| availability_zones | List of availability zones (only used if vpc_id is empty) | `list(string)` | `["us-east-1a", "us-east-1b"]` | no |
| postgres_version | PostgreSQL version | `string` | `"15.7"` | no |
| db_instance_class | RDS instance class | `string` | `"db.t3.micro"` | no |
| db_allocated_storage | Initial allocated storage for RDS instance (GB) | `number` | `20` | no |
| db_max_allocated_storage | Maximum allocated storage for RDS auto-scaling (GB) | `number` | `100` | no |
| database_name | Name of the PostgreSQL database | `string` | `"ragdb"` | no |
| database_username | Master username for PostgreSQL database | `string` | `"raguser"` | no |
| backup_retention_period | Backup retention period in days | `number` | `7` | no |
| backup_window | Backup window for RDS | `string` | `"03:00-04:00"` | no |
| maintenance_window | Maintenance window for RDS | `string` | `"sun:04:00-sun:05:00"` | no |
| deletion_protection | Enable deletion protection for RDS instance | `bool` | `false` | no |
| enable_performance_insights | Enable Performance Insights for RDS | `bool` | `false` | no |
| enable_enhanced_monitoring | Enable enhanced monitoring for RDS | `bool` | `false` | no |
| application_service_principal | AWS service principal that will assume the RAG application role | `string` | `"ec2.amazonaws.com"` | no |
| enable_bedrock_access | Enable AWS Bedrock access for the application role | `bool` | `true` | no |
| embedding_model | Bedrock model ID for embeddings | `string` | `"amazon.titan-embed-text-v1"` | no |
| text_generation_model | Bedrock model ID for text generation | `string` | `"anthropic.claude-3-sonnet-20240229-v1:0"` | no |
| tags | Tags to apply to all resources | `map(string)` | `{}` | no |

## 📤 Outputs

| Name | Description |
|------|-------------|
| s3_bucket_name | Name of the S3 bucket for document storage |
| s3_bucket_arn | ARN of the S3 bucket for document storage |
| database_endpoint | RDS instance endpoint |
| database_port | RDS instance port |
| database_name | Database name |
| database_username | Database master username (sensitive) |
| database_security_group_id | Security group ID for the database |
| application_role_arn | ARN of the IAM role for RAG application |
| application_role_name | Name of the IAM role for RAG application |
| db_credentials_secret_arn | ARN of the Secrets Manager secret containing database credentials |
| vpc_id | VPC ID where resources are deployed |
| subnet_ids | List of subnet IDs used for RDS |
| region | AWS region where resources are deployed |
| bedrock_embedding_model | Bedrock model ID for embeddings |
| bedrock_text_generation_model | Bedrock model ID for text generation |

## 🔒 Security Features

- **Encryption at Rest**: S3 and RDS encryption enabled by default
- **Network Isolation**: VPC with private subnets for database
- **IAM Least Privilege**: Minimal required permissions for application access
- **Secrets Management**: Database credentials stored securely in AWS Secrets Manager
- **Access Controls**: S3 bucket public access blocked by default

## 🛠️ Post-Deployment Setup

After deploying this module, you'll need to:

1. **Install pgvector extension** in your PostgreSQL database:
   ```sql
   CREATE EXTENSION IF NOT EXISTS vector;
   ```

2. **Configure your application** to use the outputs:
   ```python
   # Example Python configuration
   import boto3
   
   # Use the outputs to configure your RAG application
   bucket_name = "output-from-terraform"
   db_endpoint = "output-from-terraform"
   role_arn = "output-from-terraform"
   ```

3. **Set up your embedding pipeline** using the configured Bedrock models

## 🧪 Testing

To test the infrastructure:

```bash
# Deploy the module
terraform init
terraform plan
terraform apply

# Test S3 access
aws s3 ls s3://your-bucket-name

# Test database connectivity
psql -h your-db-endpoint -U raguser -d ragdb
```

## 🔄 Versioning

This module follows [Semantic Versioning](https://semver.org/). See [CHANGELOG.md](CHANGELOG.md) for release history.

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests
5. Submit a pull request

## 📄 License

This module is licensed under the MIT License. See [LICENSE](LICENSE) for details.

## 📞 Support

- 📚 [Documentation](https://github.com/your-username/terraform-aws-rag-infrastructure)
- 🐛 [Issue Tracker](https://github.com/your-username/terraform-aws-rag-infrastructure/issues)
- 💬 [Discussions](https://github.com/your-username/terraform-aws-rag-infrastructure/discussions)

## 🙏 Acknowledgments

- AWS Bedrock team for providing excellent AI models
- pgvector contributors for the PostgreSQL vector extension
- Terraform community for best practices and examples

---

**Made with ❤️ for the AI/ML community**
