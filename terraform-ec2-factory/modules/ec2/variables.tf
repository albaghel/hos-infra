variable "ami" {
  description = "AMI ID for the instance"
  type        = string
}

variable "instance_type" {
  description = "Instance type"
  type        = string
}

variable "subnet_id" {
  description = "Subnet ID where the instance will be launched"
  type        = string
}

variable "volume_size" {
  description = "Root volume size in GB"
  type        = number
  default     = 20
}

variable "volume_type" {
  description = "Root volume type"
  type        = string
  default     = "gp3"
}

variable "user_data" {
  description = "User data content (string)"
  type        = string
  default     = null
}

variable "server_name" {
  description = "Custom name for the EC2 instance"
  type        = string
}

variable "sg_name" {
  description = "Custom name for the Security Group"
  type        = string
}

variable "iam_role_name" {
  description = "Custom name for the IAM Role"
  type        = string
}

variable "key_pair_name" {
  description = "Custom name for the Key Pair"
  type        = string
}

variable "tags" {
  description = "Additional tags for the instance"
  type        = map(string)
  default     = {}
}

variable "create_security_group" {
  description = "Whether to create a new security group"
  type        = bool
  default     = true
}

variable "existing_security_group_ids" {
  description = "List of existing security group IDs to attach"
  type        = list(string)
  default     = []
}
