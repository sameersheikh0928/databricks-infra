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

# --- Create Catalog ---
resource "databricks_catalog" "this" {
  name    = "sameer_catalog"
  comment = "Main catalog for Sameer workspace managed by Terraform"

  properties = {
    purpose = "development"
  }
}

# --- Create Schema inside the Catalog ---
resource "databricks_schema" "dev" {
  catalog_name = databricks_catalog.this.name
  name         = "sameer_workspace_dev"
  comment      = "Dev schema managed by Terraform"

  depends_on = [databricks_catalog.this]
}