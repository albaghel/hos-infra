# ==============================================================
# Root Module Variables
# ==============================================================
# Set these via a terraform.tfvars file or TF_VAR_* environment
# variables.  Developers do NOT need to modify this file.
#
# Example terraform.tfvars:
#   aws_region  = "us-east-1"
#   project     = "acme-platform"
#   environment = "prod"
# ==============================================================

variable "aws_region" {
  description = "AWS region where all resources will be deployed (e.g., us-east-1)."
  type        = string
  default     = "us-east-1"

  validation {
    condition     = can(regex("^[a-z]{2}-[a-z]+-[0-9]$", var.aws_region))
    error_message = "Must be a valid AWS region format, e.g. us-east-1 or eu-west-2."
  }
}

variable "project" {
  description = "Project name applied to all resource tags and used in name prefixes."
  type        = string

  validation {
    condition     = length(var.project) >= 1 && length(var.project) <= 64
    error_message = "Project name must be 1–64 characters."
  }
}

variable "environment" {
  description = "Deployment environment. Controls tagging and can drive other policies."
  type        = string

  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Environment must be one of: dev, staging, prod."
  }
}

variable "vpc_id" {
  description = "VPC ID where all instances are deployed."
  type        = string

  validation {
    condition     = can(regex("^vpc-[0-9a-f]{8,17}$", var.vpc_id))
    error_message = "Must be a valid VPC ID (e.g., vpc-0123456789abcdef0)."
  }
}

variable "subnet_id" {
  description = "Subnet ID where instances are launched."
  type        = string

  validation {
    condition     = can(regex("^subnet-[0-9a-f]{8,17}$", var.subnet_id))
    error_message = "Must be a valid subnet ID (e.g., subnet-0123456789abcdef0)."
  }
}

variable "security_group_ids" {
  description = "List of security group IDs attached to every instance."
  type        = list(string)

  validation {
    condition     = length(var.security_group_ids) >= 1
    error_message = "At least one security group ID must be provided."
  }

  validation {
    condition = alltrue([
      for sg in var.security_group_ids : can(regex("^sg-[0-9a-f]{8,17}$", sg))
    ])
    error_message = "All security group IDs must be valid (e.g., sg-0123456789abcdef0)."
  }
}

variable "key_name" {
  description = "EC2 key pair name for SSH access. Null disables key-based SSH."
  type        = string
  default     = null
}

variable "iam_instance_profile" {
  description = "IAM instance profile name to attach to all instances. Null attaches no profile."
  type        = string
  default     = null
}
