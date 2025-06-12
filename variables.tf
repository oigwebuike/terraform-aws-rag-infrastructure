# variables.tf
variable "name_prefix" {
  description = "Prefix for all resource names"
  type        = string
  default     = "rag"
}

variable "bucket_name" {
  description = "S3 bucket name for document storage. If empty, a unique name will be generated"
  type        = string
  default     = ""
}

variable "enable_versioning" {
  description = "Enable S3 bucket versioning"
  type        = bool
  default     = true
}

variable "vpc_id" {
  description = "VPC ID to deploy resources in. If empty, a new VPC will be created"
  type        = string
  default     = ""
}

variable "vpc_cidr" {
  description = "CIDR block for VPC (only used if vpc_id is empty)"
  type        = string
  default     = "10.0.0.0/16"
}

variable "subnet_ids" {
  description = "List of subnet IDs for RDS (required if vpc_id is provided)"
  type        = list(string)
  default     = []
}

variable "availability_zones" {
  description = "List of availability zones (auto-detected if empty)"
  type        = list(string)
  default     = []  # Empty = auto-detect
}

variable "postgres_version" {
  description = "PostgreSQL version"
  type        = string
  default     = "15.7"
}

variable "db_instance_class" {
  description = "RDS instance class"
  type        = string
  default     = "db.t3.micro"
}

variable "db_allocated_storage" {
  description = "Initial allocated storage for RDS instance (GB)"
  type        = number
  default     = 20
}

variable "db_max_allocated_storage" {
  description = "Maximum allocated storage for RDS auto-scaling (GB)"
  type        = number
  default     = 100
}

variable "database_name" {
  description = "Name of the PostgreSQL database"
  type        = string
  default     = "ragdb"
}

variable "database_username" {
  description = "Master username for PostgreSQL database"
  type        = string
  default     = "raguser"
}

variable "backup_retention_period" {
  description = "Backup retention period in days"
  type        = number
  default     = 7
}

variable "backup_window" {
  description = "Backup window for RDS"
  type        = string
  default     = "03:00-04:00"
}

variable "maintenance_window" {
  description = "Maintenance window for RDS"
  type        = string
  default     = "sun:04:00-sun:05:00"
}

variable "deletion_protection" {
  description = "Enable deletion protection for RDS instance"
  type        = bool
  default     = false
}

variable "enable_performance_insights" {
  description = "Enable Performance Insights for RDS"
  type        = bool
  default     = false
}

variable "enable_enhanced_monitoring" {
  description = "Enable enhanced monitoring for RDS"
  type        = bool
  default     = false
}

variable "application_service_principal" {
  description = "AWS service principal that will assume the RAG application role"
  type        = string
  default     = "ec2.amazonaws.com"
}

variable "enable_bedrock_access" {
  description = "Enable AWS Bedrock access for the application role"
  type        = bool
  default     = true
}

variable "embedding_model" {
  description = "Bedrock model ID for embeddings"
  type        = string
  default     = "amazon.titan-embed-text-v1"
}

variable "text_generation_model" {
  description = "Bedrock model ID for text generation"
  type        = string
  default     = "anthropic.claude-3-sonnet-20240229-v1:0"
}

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default     = {}
}


# 6. Additional Variables for New Features

variable "enable_monitoring" {
  description = "Enable CloudWatch monitoring and alerting"
  type        = bool
  default     = false
}

variable "log_retention_days" {
  description = "CloudWatch logs retention period in days"
  type        = number
  default     = 30
}

variable "sns_topic_arn" {
  description = "SNS topic ARN for CloudWatch alarms"
  type        = string
  default     = ""
}

variable "enable_document_processing" {
  description = "Enable Lambda function for automatic document processing"
  type        = bool
  default     = false
}

variable "enable_api_gateway" {
  description = "Enable API Gateway for REST API"
  type        = bool
  default     = false
}

variable "enable_vector_cache" {
  description = "Enable ElastiCache Redis for vector caching"
  type        = bool
  default     = false
}

variable "cache_node_type" {
  description = "ElastiCache node type"
  type        = string
  default     = "cache.t3.micro"
}

variable "enable_opensearch" {
  description = "Enable OpenSearch for full-text search"
  type        = bool
  default     = false
}

variable "opensearch_instance_type" {
  description = "OpenSearch instance type"
  type        = string
  default     = "t3.small.search"
}

variable "opensearch_instance_count" {
  description = "Number of OpenSearch instances"
  type        = number
  default     = 1
}

variable "opensearch_volume_size" {
  description = "OpenSearch EBS volume size in GB"
  type        = number
  default     = 20
}
