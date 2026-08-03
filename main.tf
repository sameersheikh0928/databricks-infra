terraform {
  cloud {
    organization = "SAMEER_snowflake"

    workspaces {
      name = "databricks-prod"
    }
  }

  required_providers {
    databricks = {
      source  = "databricks/databricks"
      version = "~> 1.50"
    }
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    time = {
      source  = "hashicorp/time"
      version = "~> 0.9"
    }
  }
}

provider "databricks" {
  host  = var.databricks_host
  token = var.databricks_token
}

provider "aws" {
  region     = var.aws_region
  access_key = var.aws_access_key
  secret_key = var.aws_secret_key
}

# --- S3 folder ---
resource "aws_s3_object" "catalog_folder" {
  bucket  = var.s3_bucket_name
  key     = "databricks-catalog/"
  content = ""
}

# --- IAM Role ---
resource "aws_iam_role" "databricks_role" {
  name = var.aws_iam_role_name

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "DatabricksUnityPolicy"
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::414351767826:role/unity-catalog-prod-UCMasterRole-14S5ZJVKOTYTL"
        }
        Action = "sts:AssumeRole"
        Condition = {
          StringEquals = {
            "sts:ExternalId" = "f3230d94-12c6-4e7f-82a3-53ea9f191a35"
          }
        }
      },
      {
        Sid    = "SelfAssume"
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::${var.aws_account_id}:role/${var.aws_iam_role_name}"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })

  tags = {
    ManagedBy   = "Terraform"
    Environment = "dev"
  }
}

# --- IAM Policy ---
resource "aws_iam_role_policy" "databricks_s3" {
  name = "databricks-s3-policy"
  role = aws_iam_role.databricks_role.name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject",
          "s3:ListBucket",
          "s3:GetBucketLocation",
          "s3:GetLifecycleConfiguration",
          "s3:PutLifecycleConfiguration"
        ]
        Resource = [
          "arn:aws:s3:::${var.s3_bucket_name}",
          "arn:aws:s3:::${var.s3_bucket_name}/*"
        ]
      }
    ]
  })
}

# --- Schema inside existing workspace catalog ---
resource "databricks_schema" "dev" {
  catalog_name = "workspace"
  name         = "sameer_schema_dev"
  comment      = "Dev schema managed by Terraform"

  properties = {
    environment = "dev"
    managed_by  = "terraform"
  }
}

# --- Outputs ---
output "schema_name" {
  value       = databricks_schema.dev.name
  description = "Databricks schema name"
}

output "iam_role_arn" {
  value       = aws_iam_role.databricks_role.arn
  description = "IAM role ARN"
}