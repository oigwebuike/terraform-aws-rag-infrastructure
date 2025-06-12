# examples/existing-vpc/outputs.tf
output "rag_infrastructure" {
  description = "RAG infrastructure details"
  value = {
    bucket_name       = module.rag_infrastructure.s3_bucket_name
    database_endpoint = module.rag_infrastructure.database_endpoint
    role_arn         = module.rag_infrastructure.application_role_arn
    vpc_id           = module.rag_infrastructure.vpc_id
  }
}