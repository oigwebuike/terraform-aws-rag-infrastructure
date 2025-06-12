# outputs.tf
output "s3_bucket_name" {
  description = "Name of the S3 bucket for document storage"
  value       = aws_s3_bucket.document_store.bucket
}

output "s3_bucket_arn" {
  description = "ARN of the S3 bucket for document storage"
  value       = aws_s3_bucket.document_store.arn
}

output "database_endpoint" {
  description = "RDS instance endpoint"
  value       = aws_db_instance.rag_vector_db.endpoint
}

output "database_port" {
  description = "RDS instance port"
  value       = aws_db_instance.rag_vector_db.port
}

output "database_name" {
  description = "Database name"
  value       = aws_db_instance.rag_vector_db.db_name
}

output "database_username" {
  description = "Database master username"
  value       = aws_db_instance.rag_vector_db.username
  sensitive   = true
}

output "database_security_group_id" {
  description = "Security group ID for the database"
  value       = aws_security_group.rag_db_sg.id
}

output "application_role_arn" {
  description = "ARN of the IAM role for RAG application"
  value       = aws_iam_role.rag_application_role.arn
}

output "application_role_name" {
  description = "Name of the IAM role for RAG application"
  value       = aws_iam_role.rag_application_role.name
}

output "db_credentials_secret_arn" {
  description = "ARN of the Secrets Manager secret containing database credentials"
  value       = aws_secretsmanager_secret.db_credentials.arn
}

output "vpc_id" {
  description = "VPC ID where resources are deployed"
  value       = var.vpc_id == "" ? aws_vpc.rag_vpc[0].id : var.vpc_id
}

output "subnet_ids" {
  description = "List of subnet IDs used for RDS"
  value       = var.vpc_id == "" ? aws_subnet.rag_private_subnets[*].id : var.subnet_ids
}

output "region" {
  description = "AWS region where resources are deployed"
  value       = data.aws_region.current.name
}

output "bedrock_embedding_model" {
  description = "Bedrock model ID for embeddings"
  value       = var.embedding_model
}

output "bedrock_text_generation_model" {
  description = "Bedrock model ID for text generation"
  value       = var.text_generation_model
}

# 9. Additional Outputs for New Features

output "lambda_function_arn" {
  description = "ARN of the document processing Lambda function"
  value       = var.enable_document_processing ? aws_lambda_function.document_processor[0].arn : null
}

output "api_gateway_url" {
  description = "URL of the API Gateway"
  value       = var.enable_api_gateway ? aws_api_gateway_rest_api.rag_api[0].execution_arn : null
}

output "cache_endpoint" {
  description = "ElastiCache Redis endpoint"
  value       = var.enable_vector_cache ? aws_elasticache_cluster.rag_vector_cache[0].cache_nodes[0].address : null
}

output "opensearch_endpoint" {
  description = "OpenSearch domain endpoint"
  value       = var.enable_opensearch ? aws_opensearch_domain.rag_search[0].endpoint : null
}

output "cloudwatch_log_group" {
  description = "CloudWatch log group for application logs"
  value       = var.enable_monitoring ? aws_cloudwatch_log_group.rag_application_logs[0].name : null
}