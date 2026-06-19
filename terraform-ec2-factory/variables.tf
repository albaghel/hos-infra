variable "aws_region" {
  description = "The AWS region to deploy to"
  type        = string
  default     = "ap-south-1"
}

variable "default_tags" {
  description = "Default tags to apply to all resources"
  type        = map(string)
  default     = {}
}

variable "servers" {
  description = "Map of server configurations to provision"
  type = map(object({
    ami            = string
    instance_type  = string
    subnet_id      = string
    volume_size    = optional(number, 20)
    volume_type    = optional(string, "gp3")
    user_data_file              = optional(string)
    username                    = optional(string)
    create_security_group       = optional(bool, true)
    existing_security_group_ids = optional(list(string), [])
    server_name                 = optional(string)
    sg_name                     = optional(string)
    iam_role_name               = optional(string)
    key_pair_name               = optional(string)
    tags                        = optional(map(string), {})
  }))
  default = {}

  validation {
    condition = alltrue([
      for k, v in var.servers : contains(["gp2", "gp3", "io1", "io2", "standard"], v.volume_type)
    ])
    error_message = "The volume_type must be one of: gp2, gp3, io1, io2, standard."
  }
}
