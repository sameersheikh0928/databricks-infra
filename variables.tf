variable "databricks_host" {
  type        = string
  description = "Databricks workspace URL"
}

variable "databricks_token" {
  type      = string
  sensitive = true
}

variable "aws_iam_role_arn" {
  type        = string
  description = "IAM role ARN for Databricks S3 access"
}

