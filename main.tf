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

# --- S3 folder for catalog ---
resource "aws_s3_object" "catalog_folder" {
  bucket  = var.s3_bucket_name
  key     = "databricks-catalog/"
  content = ""
}

# --- Storage credential ---
resource "databricks_storage_credential" "this" {
  name = "sameer-s3-credential"

  aws_iam_role {
    role_arn = var.aws_iam_role_arn
  }

  comment    = "S3 storage credential for Databricks catalog"
  depends_on = [aws_s3_object.catalog_folder]
}

# --- Outputs to get External ID and IAM ARN ---
output "databricks_external_id" {
  value       = databricks_storage_credential.this.aws_iam_role[0].external_id
  description = "Paste this External ID into your IAM trust policy"
}

output "databricks_iam_user_arn" {
  value       = databricks_storage_credential.this.aws_iam_role[0].unity_catalog_iam_arn
  description = "Paste this ARN as Principal into your IAM trust policy"
}