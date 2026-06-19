# ==============================================================
# AWS Provider Configuration
# ==============================================================
# Region is driven by var.aws_region so the same codebase can
# target different regions without code changes.
#
# default_tags applies Project, Environment, and ManagedBy to
# every resource created by this provider, ensuring consistent
# tagging even if a resource is added without explicit tags.
# ==============================================================

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Project     = var.project
      Environment = var.environment
      ManagedBy   = "Terraform"
    }
  }
}
