# examples/basic/README.md
# Basic RAG Infrastructure Example

This example demonstrates the minimal configuration needed to deploy RAG infrastructure.

## Overview

This example creates:
- S3 bucket for document storage
- PostgreSQL RDS instance (db.t3.micro for cost optimization)
- New VPC with private subnets
- IAM roles and policies
- Secrets Manager for database credentials
- AWS Bedrock integration

## Usage

```bash
# Initialize Terraform
terraform init

# Review the plan
terraform plan

# Deploy infrastructure (costs ~$0.10-0.25/hour)
terraform apply

# View results
terraform output

# Clean up when done
terraform destroy
```

## Outputs

- `test_results` - Summary of created resources
- `connection_test` - Command to connect to database
- `secrets_command` - Command to retrieve database password
- `infrastructure_summary` - Complete infrastructure details

## Cost Estimation

**Approximate costs (us-east-1):**
- RDS db.t3.micro: ~$0.017/hour ($12/month)
- S3 storage: ~$0.023/GB/month
- Secrets Manager: $0.40/month per secret
- VPC/Networking: Free tier eligible

**Total: ~$13-15/month for basic usage**

## Post-Deployment

After deployment, you'll need to:

1. **Install pgvector extension:**
   ```sql
   CREATE EXTENSION IF NOT EXISTS vector;
   ```

2. **Get database password:**
   ```bash
   aws secretsmanager get-secret-value --secret-id $(terraform output -raw secrets_command | cut -d' ' -f6) --query SecretString --output text
   ```

3. **Connect to database:**
   ```bash
   # Get connection command
   terraform output connection_test
   
   # Use the command (you'll be prompted for password)
   psql -h your-db-endpoint -U raguser -d ragdb
   ```

## Next Steps

- See [../../docs/post-deployment.md](../../docs/post-deployment.md) for detailed setup
- Try the [complete example](../complete/) for production features
- Review [existing-vpc example](../existing-vpc/) for using existing infrastructure