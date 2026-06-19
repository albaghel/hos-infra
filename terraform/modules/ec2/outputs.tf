# ==============================================================
# EC2 Module Outputs
# ==============================================================
# Consumed by the root module's outputs.tf to build the project-
# wide output maps (instance_ids, private_ips, public_ips, etc.).
# ==============================================================

output "instance_id" {
  description = "The EC2 instance ID (e.g., i-0abc123def456789a)."
  value       = aws_instance.this.id
}

output "private_ip" {
  description = "The primary private IPv4 address of the instance."
  value       = aws_instance.this.private_ip
}

output "public_ip" {
  description = "The public IPv4 address. Empty string when associate_public_ip is false."
  value       = aws_instance.this.public_ip
}

output "arn" {
  description = "The ARN of the EC2 instance."
  value       = aws_instance.this.arn
}

output "availability_zone" {
  description = "The Availability Zone the instance was launched in."
  value       = aws_instance.this.availability_zone
}

output "primary_network_interface_id" {
  description = "The ID of the primary network interface."
  value       = aws_instance.this.primary_network_interface_id
}
