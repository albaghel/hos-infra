# ==============================================================
# EC2 Module Variables
# ==============================================================
# These variables are populated by the root module (main.tf) and
# should not be set manually.  All defaults and optional-field
# handling are normalised in locals.tf before reaching here.
# ==============================================================

# --- Identity ---

variable "name" {
  description = "Instance name. Used as the Terraform resource key, Name tag, and volume name prefix."
  type        = string

  validation {
    condition     = can(regex("^[a-z0-9]([a-z0-9-]*[a-z0-9])?$", var.name))
    error_message = "Name must be lowercase alphanumeric with optional internal hyphens (e.g., web-server-1). Cannot start or end with a hyphen."
  }
}

variable "project" {
  description = "Project name applied as a resource tag."
  type        = string

  validation {
    condition     = length(var.project) >= 1
    error_message = "Project name cannot be empty."
  }
}

variable "environment" {
  description = "Deployment environment applied as a resource tag."
  type        = string

  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Environment must be one of: dev, staging, prod."
  }
}

# --- Compute ---

variable "ami_id" {
  description = "EC2 AMI ID resolved by the root module from the ami_type in servers.yaml."
  type        = string

  validation {
    condition     = can(regex("^ami-[0-9a-f]{8,17}$", var.ami_id))
    error_message = "ami_id must be a valid AMI ID (e.g., ami-0c02fb55956c7d316)."
  }
}

variable "instance_type" {
  description = "EC2 instance type (e.g., t3.medium, m5.xlarge, r5.2xlarge)."
  type        = string

  validation {
    # Covers standard type families: t3, m5, r5, c5, p3, i3, trn1, inf2, etc.
    condition     = can(regex("^[a-z][0-9a-z]+\\.[0-9a-z]+$", var.instance_type))
    error_message = "Must be a valid EC2 instance type (e.g., t3.medium, m5.2xlarge)."
  }
}

# --- Storage ---

variable "volume_size" {
  description = "Root EBS volume size in gigabytes."
  type        = number

  validation {
    condition     = var.volume_size >= 8 && var.volume_size <= 16384
    error_message = "Root volume size must be between 8 GB and 16384 GB."
  }
}

variable "additional_volumes" {
  description = "Optional list of extra EBS data volumes to attach to the instance."
  type = list(object({
    device_name = string
    volume_size = number
    volume_type = optional(string, "gp3")
  }))
  default = []

  validation {
    condition = alltrue([
      for v in var.additional_volumes : v.volume_size >= 1 && v.volume_size <= 16384
    ])
    error_message = "Each additional volume size must be between 1 GB and 16384 GB."
  }

  validation {
    condition = alltrue([
      for v in var.additional_volumes :
      contains(["gp2", "gp3", "io1", "io2", "sc1", "st1", "standard"], v.volume_type)
    ])
    error_message = "volume_type must be one of: gp2, gp3, io1, io2, sc1, st1, standard."
  }
}

# --- Networking ---

variable "subnet_id" {
  description = "Subnet ID where the instance will be launched."
  type        = string

  validation {
    condition     = can(regex("^subnet-[0-9a-f]{8,17}$", var.subnet_id))
    error_message = "Must be a valid subnet ID (e.g., subnet-0123456789abcdef0)."
  }
}

variable "security_group_ids" {
  description = "List of security group IDs to attach to the instance."
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

variable "associate_public_ip" {
  description = "Whether to assign a public IP address to the instance."
  type        = bool
  default     = true
}

# --- Access ---

variable "key_name" {
  description = "Name of the EC2 key pair for SSH access. Null disables key-based SSH."
  type        = string
  default     = null
}

variable "iam_instance_profile" {
  description = "Name of the IAM instance profile to attach. Null attaches no profile."
  type        = string
  default     = null
}

# --- Bootstrap ---

variable "user_data" {
  description = "Raw user data script content to execute on first boot. Null skips bootstrapping."
  type        = string
  default     = null
  sensitive   = false
}
