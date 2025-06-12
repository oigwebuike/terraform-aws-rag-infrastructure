# examples/basic/variables.tf
variable "aws_region" {
  description = "AWS region for testing"
  type        = string
  default     = "us-east-1"
}

variable "name_prefix" {
  description = "Prefix for test resources"
  type        = string
  default     = "test-rag"
}