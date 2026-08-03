variable "databricks_host" {
  type        = string
  description = "Databricks workspace URL"
}

variable "databricks_token" {
  type      = string
  sensitive = true
}

variable "aws_region" {
  type    = string
  default = "us-east-2"
}

variable "aws_access_key" {
  type      = string
  sensitive = true
}

variable "aws_secret_key" {
  type      = string
  sensitive = true
}

variable "s3_bucket_name" {
  type    = string
  default = "targetdemo"
}

variable "aws_iam_role_arn" {
  type        = string
  description = "IAM role ARN for Databricks S3 access"
}

variable "aws_iam_role_name" {
  type        = string
  description = "IAM role name for Databricks S3 access"
  default     = "databricks-s3-role"
}