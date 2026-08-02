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
  }
}

provider "databricks" {
  host  = var.databricks_host
  token = var.databricks_token
}

resource "databricks_storage_credential" "this" {
  name = "sameer-s3-credential"

  aws_iam_role {
    role_arn = var.aws_iam_role_arn
  }

  comment = "S3 storage credential for Databricks catalog"
}

resource "databricks_external_location" "this" {
  name            = "sameer-s3-location"
  url             = "s3://targetdemo/databricks-catalog"
  credential_name = databricks_storage_credential.this.name
  comment         = "External location for targetdemo S3 bucket"

  depends_on = [databricks_storage_credential.this]
}

resource "databricks_catalog" "this" {
  name         = "sameer_catalog"
  comment      = "Main catalog managed by Terraform"
  storage_root = "s3://targetdemo/databricks-catalog"

  depends_on = [databricks_external_location.this]
}

resource "databricks_schema" "dev" {
  catalog_name = databricks_catalog.this.name
  name         = "sameer_workspace_dev"
  comment      = "Dev schema managed by Terraform"

  depends_on = [databricks_catalog.this]
}



