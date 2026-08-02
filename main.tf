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

resource "databricks_catalog" "this" {
  name         = "sameer_catalog"
  comment      = "Main catalog managed by Terraform"
  storage_root = "s3://targetdemo/databricks-catalog"

  properties = {
    purpose = "development"
  }
}

resource "databricks_schema" "dev" {