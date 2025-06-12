# examples/basic/outputs.tf
output "test_results" {
  description = "Test results summary"
  value = {
    bucket_name       = module.rag_infrastructure.s3_bucket_name
    database_endpoint = module.rag_infrastructure.database_endpoint
    vpc_id           = module.rag_infrastructure.vpc_id
    region           = module.rag_infrastructure.region
  }
}

output "connection_test" {
  description = "Database connection command for testing"
  value = "psql -h ${module.rag_infrastructure.database_endpoint} -U ${module.rag_infrastructure.database_username} -d ${module.rag_infrastructure.database_name}"
  sensitive = true
}

output "secrets_command" {
  description = "Command to get database password"
  value = "aws secretsmanager get-secret-value --secret-id ${module.rag_infrastructure.db_credentials_secret_arn} --query SecretString --output text"
}

output "infrastructure_summary" {
  description = "Summary of created infrastructure"
  value = {
    bucket_name         = module.rag_infrastructure.s3_bucket_name
    bucket_arn          = module.rag_infrastructure.s3_bucket_arn
    database_endpoint   = module.rag_infrastructure.database_endpoint
    database_port       = module.rag_infrastructure.database_port
    database_name       = module.rag_infrastructure.database_name
    application_role    = module.rag_infrastructure.application_role_name
    vpc_id             = module.rag_infrastructure.vpc_id
    region             = module.rag_infrastructure.region
    embedding_model    = module.rag_infrastructure.bedrock_embedding_model
    generation_model   = module.rag_infrastructure.bedrock_text_generation_model
  }
}