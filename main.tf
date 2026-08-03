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

# --- Step 1: Create S3 folder for catalog ---
resource "aws_s3_object" "catalog_folder" {
  bucket  = var.s3_bucket_name
  key     = "databricks-catalog/"
  content = ""
}

# --- Step 2: Create storage credential ---
resource "databricks_storage_credential" "this" {
  name = "sameer-s3-credential"

  aws_iam_role {
    role_arn = var.aws_iam_role_arn
  }

  comment    = "S3 storage credential for Databricks catalog"
  depends_on = [aws_s3_object.catalog_folder]
}

# --- Step 3: Update IAM trust policy with Databricks-generated external ID ---
resource "aws_iam_role_policy" "databricks_s3" {
  name = "databricks-s3-policy"
  role = var.aws_iam_role_name

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

resource "aws_iam_role" "databricks_role" {
  name = var.aws_iam_role_name

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::414351767826:root"
        }
        Action = "sts:AssumeRole"
        Condition = {
          StringEquals = {
            "sts:ExternalId" = databricks_storage_credential.this.aws_iam_role[0].external_id
          }
        }
      }
    ]
  })
}

# --- Step 4: Create external location ---
resource "databricks_external_location" "this" {
  name            = "sameer-s3-location"
  url             = "s3://${var.s3_bucket_name}/databricks-catalog"
  credential_name = databricks_storage_credential.this.name
  comment         = "External location for targetdemo S3 bucket"

  depends_on = [
    databricks_storage_credential.this,
    aws_iam_role.databricks_role
  ]
}

# --- Step 5: Create catalog ---
resource "databricks_catalog" "this" {
  name         = "sameer_catalog"
  comment      = "Main catalog managed by Terraform"
  storage_root = "s3://${var.s3_bucket_name}/databricks-catalog"

  depends_on = [databricks_external_location.this]
}

# --- Step 6: Create schema ---
resource "databricks_schema" "dev" {
  catalog_name = databricks_catalog.this.name
  name         = "sameer_workspace_dev"
  comment      = "Dev schema managed by Terraform"

  depends_on = [databricks_catalog.this]
}