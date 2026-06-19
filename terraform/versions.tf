# ==============================================================
# Terraform and Provider Version Constraints
# ==============================================================
# Pinning the AWS provider to the ~> 5.0 range allows minor
# version upgrades (bug fixes, new resources) but prevents
# accidental major-version upgrades that may include breaking
# changes.
# ==============================================================

terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}
