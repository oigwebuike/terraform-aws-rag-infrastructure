# examples/complete/outputs.tf
output "infrastructure_summary" {
  description = "Summary of created infrastructure"
  value = {
    bucket_name         = module.rag_infrastructure.s3_bucket_name
    database_endpoint   = module.rag_infrastructure.database_endpoint
    application_role    = module.rag_infrastructure.application_role_name
    vpc_id             = module.rag_infrastructure.vpc_id
    region             = module.rag_infrastructure.region
    embedding_model    = module.rag_infrastructure.bedrock_embedding_model
    generation_model   = module.rag_infrastructure.bedrock_text_generation_model
  }
}

output "database_connection_info" {
  description = "Database connection information"
  value = {
    endpoint = module.rag_infrastructure.database_endpoint
    port     = module.rag_infrastructure.database_port
    database = module.rag_infrastructure.database_name
    username = module.rag_infrastructure.database_username
  }
  sensitive = true
}

output "secrets_manager_arn" {
  description = "ARN of the Secrets Manager secret containing database credentials"
  value       = module.rag_infrastructure.db_credentials_secret_arn
}
