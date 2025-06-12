# main.tf
# Data sources
data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

locals {
  # Use provided AZs or auto-detect first 2 available
  availability_zones = length(var.availability_zones) > 0 ? var.availability_zones : slice(data.aws_availability_zones.available.names, 0, 2)
}

# Random password for RDS
resource "random_password" "db_password" {
  length  = 16
  special = true
}

# S3 bucket for document storage
resource "aws_s3_bucket" "document_store" {
  bucket = var.bucket_name != "" ? var.bucket_name : "${var.name_prefix}-rag-documents-${random_id.bucket_suffix.hex}"

  tags = merge(var.tags, {
    Name        = "${var.name_prefix}-document-store"
    Purpose     = "RAG document storage"
    Module      = "terraform-aws-rag-infrastructure"
  })
}

resource "random_id" "bucket_suffix" {
  byte_length = 4
}

resource "aws_s3_bucket_versioning" "document_store" {
  bucket = aws_s3_bucket.document_store.id
  versioning_configuration {
    status = var.enable_versioning ? "Enabled" : "Disabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "document_store" {
  bucket = aws_s3_bucket.document_store.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
    bucket_key_enabled = true
  }
}

resource "aws_s3_bucket_public_access_block" "document_store" {
  bucket = aws_s3_bucket.document_store.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# VPC and networking (optional, creates new VPC if not provided)
resource "aws_vpc" "rag_vpc" {
  count = var.vpc_id == "" ? 1 : 0

  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = merge(var.tags, {
    Name = "${var.name_prefix}-rag-vpc"
  })
}

resource "aws_internet_gateway" "rag_igw" {
  count = var.vpc_id == "" ? 1 : 0

  vpc_id = aws_vpc.rag_vpc[0].id

  tags = merge(var.tags, {
    Name = "${var.name_prefix}-rag-igw"
  })
}


resource "aws_subnet" "rag_private_subnets" {
  count = var.vpc_id == "" ? length(local.availability_zones) : 0

  vpc_id            = aws_vpc.rag_vpc[0].id
  cidr_block        = cidrsubnet(var.vpc_cidr, 8, count.index + 1)
  availability_zone = local.availability_zones[count.index]  # Changed this line

  tags = merge(var.tags, {
    Name = "${var.name_prefix}-rag-private-subnet-${count.index + 1}"
    Type = "Private"
  })
}

resource "aws_route_table" "rag_private" {
  count = var.vpc_id == "" ? 1 : 0

  vpc_id = aws_vpc.rag_vpc[0].id

  tags = merge(var.tags, {
    Name = "${var.name_prefix}-rag-private-rt"
  })
}

resource "aws_route_table_association" "rag_private" {
  count = var.vpc_id == "" ? length(aws_subnet.rag_private_subnets) : 0

  subnet_id      = aws_subnet.rag_private_subnets[count.index].id
  route_table_id = aws_route_table.rag_private[0].id
}

# RDS PostgreSQL with pgvector for vector storage
resource "aws_db_subnet_group" "rag_db_subnet_group" {
  name       = "${var.name_prefix}-rag-db-subnet-group"
  subnet_ids = var.vpc_id == "" ? aws_subnet.rag_private_subnets[*].id : var.subnet_ids

  tags = merge(var.tags, {
    Name = "${var.name_prefix}-rag-db-subnet-group"
  })
}

resource "aws_security_group" "rag_db_sg" {
  name_prefix = "${var.name_prefix}-rag-db-"
  vpc_id      = var.vpc_id == "" ? aws_vpc.rag_vpc[0].id : var.vpc_id

  ingress {
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = [var.vpc_id == "" ? var.vpc_cidr : "10.0.0.0/8"]
    description = "PostgreSQL access from VPC"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "All outbound traffic"
  }

  tags = merge(var.tags, {
    Name = "${var.name_prefix}-rag-db-sg"
  })
}

resource "aws_db_instance" "rag_vector_db" {
  identifier = "${var.name_prefix}-rag-vector-db"

  # Database configuration
  engine         = "postgres"
  # engine_version = var.postgres_version
  engine_version = data.aws_rds_engine_versions.postgresql.valid_engine_versions[0]

  instance_class = var.db_instance_class
  
  allocated_storage     = var.db_allocated_storage
  max_allocated_storage = var.db_max_allocated_storage
  storage_type          = "gp3"
  storage_encrypted     = true

  # Database credentials
  db_name  = var.database_name
  username = var.database_username
  password = random_password.db_password.result

  # Network configuration
  db_subnet_group_name   = aws_db_subnet_group.rag_db_subnet_group.name
  vpc_security_group_ids = [aws_security_group.rag_db_sg.id]
  publicly_accessible    = false

  # Backup configuration
  backup_retention_period = var.backup_retention_period
  backup_window          = var.backup_window
  maintenance_window     = var.maintenance_window

  # Performance and monitoring
  performance_insights_enabled = var.enable_performance_insights
  monitoring_interval         = var.enable_enhanced_monitoring ? 60 : 0
  monitoring_role_arn         = var.enable_enhanced_monitoring ? aws_iam_role.rds_enhanced_monitoring[0].arn : null

  # Deletion protection
  deletion_protection = var.deletion_protection
  skip_final_snapshot = !var.deletion_protection

  tags = merge(var.tags, {
    Name    = "${var.name_prefix}-rag-vector-db"
    Purpose = "Vector database for RAG embeddings"
  })
}

# IAM role for RDS enhanced monitoring
resource "aws_iam_role" "rds_enhanced_monitoring" {
  count = var.enable_enhanced_monitoring ? 1 : 0

  name_prefix = "${var.name_prefix}-rds-monitoring-"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "monitoring.rds.amazonaws.com"
        }
      }
    ]
  })

  tags = var.tags
}

resource "aws_iam_role_policy_attachment" "rds_enhanced_monitoring" {
  count = var.enable_enhanced_monitoring ? 1 : 0

  role       = aws_iam_role.rds_enhanced_monitoring[0].name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonRDSEnhancedMonitoringRole"
}

# IAM role for RAG application
resource "aws_iam_role" "rag_application_role" {
  name_prefix = "${var.name_prefix}-rag-app-"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = var.application_service_principal
        }
      }
    ]
  })

  tags = merge(var.tags, {
    Name = "${var.name_prefix}-rag-application-role"
  })
}

# IAM policy for S3 access
resource "aws_iam_policy" "rag_s3_access" {
  name_prefix = "${var.name_prefix}-rag-s3-"
  description = "IAM policy for RAG application S3 access"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject",
          "s3:ListBucket"
        ]
        Resource = [
          aws_s3_bucket.document_store.arn,
          "${aws_s3_bucket.document_store.arn}/*"
        ]
      }
    ]
  })

  tags = var.tags
}

# IAM policy for Bedrock access (if enabled)
resource "aws_iam_policy" "rag_bedrock_access" {
  count = var.enable_bedrock_access ? 1 : 0

  name_prefix = "${var.name_prefix}-rag-bedrock-"
  description = "IAM policy for RAG application Bedrock access"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "bedrock:InvokeModel",
          "bedrock:InvokeModelWithResponseStream"
        ]
        Resource = [
          "arn:aws:bedrock:${data.aws_region.current.name}::foundation-model/${var.embedding_model}",
          "arn:aws:bedrock:${data.aws_region.current.name}::foundation-model/${var.text_generation_model}"
        ]
      }
    ]
  })

  tags = var.tags
}

# Attach policies to application role
resource "aws_iam_role_policy_attachment" "rag_s3_access" {
  role       = aws_iam_role.rag_application_role.name
  policy_arn = aws_iam_policy.rag_s3_access.arn
}

resource "aws_iam_role_policy_attachment" "rag_bedrock_access" {
  count = var.enable_bedrock_access ? 1 : 0

  role       = aws_iam_role.rag_application_role.name
  policy_arn = aws_iam_policy.rag_bedrock_access[0].arn
}

# Store database password in AWS Secrets Manager
resource "aws_secretsmanager_secret" "db_credentials" {
  name_prefix             = "${var.name_prefix}-rag-db-credentials"
  description             = "Database credentials for RAG vector database"
  recovery_window_in_days = var.deletion_protection ? 30 : 0

  tags = merge(var.tags, {
    Name = "${var.name_prefix}-rag-db-credentials"
  })
}

resource "aws_secretsmanager_secret_version" "db_credentials" {
  secret_id = aws_secretsmanager_secret.db_credentials.id
  secret_string = jsonencode({
    username = aws_db_instance.rag_vector_db.username
    password = random_password.db_password.result
    host     = aws_db_instance.rag_vector_db.endpoint
    port     = aws_db_instance.rag_vector_db.port
    dbname   = aws_db_instance.rag_vector_db.db_name
  })
}


# api_gateway.tf

resource "aws_api_gateway_rest_api" "rag_api" {
  count = var.enable_api_gateway ? 1 : 0
  
  name        = "${var.name_prefix}-rag-api"
  description = "REST API for RAG application"

  endpoint_configuration {
    types = ["REGIONAL"]
  }

  tags = merge(var.tags, {
    Name = "${var.name_prefix}-rag-api"
  })
}

resource "aws_api_gateway_resource" "query" {
  count = var.enable_api_gateway ? 1 : 0
  
  rest_api_id = aws_api_gateway_rest_api.rag_api[0].id
  parent_id   = aws_api_gateway_rest_api.rag_api[0].root_resource_id
  path_part   = "query"
}

resource "aws_api_gateway_method" "query_post" {
  count = var.enable_api_gateway ? 1 : 0
  
  rest_api_id   = aws_api_gateway_rest_api.rag_api[0].id
  resource_id   = aws_api_gateway_resource.query[0].id
  http_method   = "POST"
  authorization = "AWS_IAM"
}


# elasticache.tf

resource "aws_elasticache_subnet_group" "rag_cache" {
  count = var.enable_vector_cache ? 1 : 0
  
  name       = "${var.name_prefix}-cache-subnet"
  subnet_ids = var.vpc_id == "" ? aws_subnet.rag_private_subnets[*].id : var.subnet_ids
}

resource "aws_security_group" "rag_cache_sg" {
  count = var.enable_vector_cache ? 1 : 0
  
  name_prefix = "${var.name_prefix}-cache-"
  vpc_id      = var.vpc_id == "" ? aws_vpc.rag_vpc[0].id : var.vpc_id

  ingress {
    from_port   = 6379
    to_port     = 6379
    protocol    = "tcp"
    cidr_blocks = [var.vpc_id == "" ? var.vpc_cidr : "10.0.0.0/8"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.tags, {
    Name = "${var.name_prefix}-cache-sg"
  })
}

resource "aws_elasticache_cluster" "rag_vector_cache" {
  count = var.enable_vector_cache ? 1 : 0
  
  cluster_id           = "${var.name_prefix}-vector-cache"
  engine               = "redis"
  node_type            = var.cache_node_type
  num_cache_nodes      = 1
  parameter_group_name = "default.redis7"
  port                 = 6379
  
  subnet_group_name  = aws_elasticache_subnet_group.rag_cache[0].name
  security_group_ids = [aws_security_group.rag_cache_sg[0].id]

  tags = merge(var.tags, {
    Name = "${var.name_prefix}-vector-cache"
  })
}


# monitoring.tf

resource "aws_cloudwatch_log_group" "rag_application_logs" {
  count = var.enable_monitoring ? 1 : 0
  
  name              = "/aws/rag/${var.name_prefix}/application"
  retention_in_days = var.log_retention_days

  tags = merge(var.tags, {
    Name = "${var.name_prefix}-application-logs"
  })
}

resource "aws_cloudwatch_metric_alarm" "database_cpu" {
  count = var.enable_monitoring ? 1 : 0
  
  alarm_name          = "${var.name_prefix}-database-cpu-high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/RDS"
  period              = "300"
  statistic           = "Average"
  threshold           = "80"
  alarm_description   = "This metric monitors RDS CPU utilization"
  alarm_actions       = var.sns_topic_arn != "" ? [var.sns_topic_arn] : []

  dimensions = {
    DBInstanceIdentifier = aws_db_instance.rag_vector_db.id
  }

  tags = var.tags
}

resource "aws_cloudwatch_metric_alarm" "s3_errors" {
  count = var.enable_monitoring ? 1 : 0
  
  alarm_name          = "${var.name_prefix}-s3-errors"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "4xxErrors"
  namespace           = "AWS/S3"
  period              = "300"
  statistic           = "Sum"
  threshold           = "10"
  alarm_description   = "This metric monitors S3 4xx errors"
  alarm_actions       = var.sns_topic_arn != "" ? [var.sns_topic_arn] : []

  dimensions = {
    BucketName = aws_s3_bucket.document_store.bucket
  }

  tags = var.tags
}


# opensearch.tf

resource "aws_opensearch_domain" "rag_search" {
  count = var.enable_opensearch ? 1 : 0
  
  domain_name    = "${var.name_prefix}-search"
  engine_version = "OpenSearch_2.3"

  cluster_config {
    instance_type  = var.opensearch_instance_type
    instance_count = var.opensearch_instance_count
  }

  ebs_options {
    ebs_enabled = true
    volume_type = "gp3"
    volume_size = var.opensearch_volume_size
  }

  vpc_options {
    subnet_ids         = var.vpc_id == "" ? slice(aws_subnet.rag_private_subnets[*].id, 0, 1) : slice(var.subnet_ids, 0, 1)
    security_group_ids = [aws_security_group.rag_opensearch_sg[0].id]
  }

  encrypt_at_rest {
    enabled = true
  }

  node_to_node_encryption {
    enabled = true
  }

  domain_endpoint_options {
    enforce_https = true
  }

  tags = merge(var.tags, {
    Name = "${var.name_prefix}-search"
  })
}

resource "aws_security_group" "rag_opensearch_sg" {
  count = var.enable_opensearch ? 1 : 0
  
  name_prefix = "${var.name_prefix}-opensearch-"
  vpc_id      = var.vpc_id == "" ? aws_vpc.rag_vpc[0].id : var.vpc_id

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [var.vpc_id == "" ? var.vpc_cidr : "10.0.0.0/8"]
  }

  tags = merge(var.tags, {
    Name = "${var.name_prefix}-opensearch-sg"
  })
}



# lambda.tf

resource "aws_lambda_function" "document_processor" {
  count = var.enable_document_processing ? 1 : 0
  
  filename      = data.archive_file.lambda_zip[0].output_path
  function_name = "${var.name_prefix}-document-processor"
  role          = aws_iam_role.lambda_role[0].arn
  handler       = "index.handler"
  runtime       = "python3.9"
  timeout       = 300

  source_code_hash = data.archive_file.lambda_zip[0].output_base64sha256

  environment {
    variables = {
      BUCKET_NAME = aws_s3_bucket.document_store.bucket
      DB_SECRET_ARN = aws_secretsmanager_secret.db_credentials.arn
      EMBEDDING_MODEL = var.embedding_model
    }
  }

  tags = merge(var.tags, {
    Name = "${var.name_prefix}-document-processor"
  })
}

data "archive_file" "lambda_zip" {
  count = var.enable_document_processing ? 1 : 0
  
  type        = "zip"
  output_path = "${path.module}/lambda_function.zip"
  source {
    content = templatefile("${path.module}/lambda/document_processor.py", {
      bucket_name = aws_s3_bucket.document_store.bucket
    })
    filename = "index.py"
  }
}

resource "aws_iam_role" "lambda_role" {
  count = var.enable_document_processing ? 1 : 0
  
  name_prefix = "${var.name_prefix}-lambda-"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })

  tags = var.tags
}

resource "aws_iam_role_policy_attachment" "lambda_basic" {
  count = var.enable_document_processing ? 1 : 0
  
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
  role       = aws_iam_role.lambda_role[0].name
}

# S3 trigger for Lambda
resource "aws_s3_bucket_notification" "document_upload" {
  count = var.enable_document_processing ? 1 : 0
  
  bucket = aws_s3_bucket.document_store.id

  lambda_function {
    lambda_function_arn = aws_lambda_function.document_processor[0].arn
    events             = ["s3:ObjectCreated:*"]
    filter_prefix      = "documents/"
    filter_suffix      = ".pdf"
  }

  depends_on = [aws_lambda_permission.s3_invoke[0]]
}

resource "aws_lambda_permission" "s3_invoke" {
  count = var.enable_document_processing ? 1 : 0
  
  statement_id  = "AllowExecutionFromS3Bucket"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.document_processor[0].function_name
  principal     = "s3.amazonaws.com"
  source_arn    = aws_s3_bucket.document_store.arn
}

data "aws_availability_zones" "available" {
  state = "available"
}

data "aws_rds_engine_versions" "postgresql" {
  engine = "postgres"
  preferred_versions = ["15.7", "15.6", "15.5", "14.12", "14.11"]
}