# ==============================================================
# Root Module Outputs
# ==============================================================
# All outputs are maps keyed by instance name so callers (CI
# pipelines, other modules, scripts) can reference individual
# values without parsing a flat list.
#
# Example access:
#   terraform output -json instance_ids | jq '.jenkins'
# ==============================================================

output "instance_ids" {
  description = "Map of instance name → EC2 instance ID."
  value       = { for k, v in module.ec2 : k => v.instance_id }
}

output "private_ips" {
  description = "Map of instance name → private IPv4 address."
  value       = { for k, v in module.ec2 : k => v.private_ip }
}

output "public_ips" {
  description = "Map of instance name → public IPv4 address. Null if associate_public_ip is false."
  value       = { for k, v in module.ec2 : k => v.public_ip }
}

output "instance_arns" {
  description = "Map of instance name → EC2 instance ARN."
  value       = { for k, v in module.ec2 : k => v.arn }
}

output "availability_zones" {
  description = "Map of instance name → Availability Zone the instance was placed in."
  value       = { for k, v in module.ec2 : k => v.availability_zone }
}

output "instance_summary" {
  description = "Consolidated summary of all provisioned instances."
  value = {
    for k, v in module.ec2 : k => {
      id                = v.instance_id
      arn               = v.arn
      private_ip        = v.private_ip
      public_ip         = v.public_ip
      availability_zone = v.availability_zone
    }
  }
}
