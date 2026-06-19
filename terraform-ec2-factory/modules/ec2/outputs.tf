output "instance_id" {
  description = "ID of the created EC2 instance"
  value       = aws_instance.server.id
}

output "private_ip" {
  description = "Private IP of the instance"
  value       = aws_instance.server.private_ip
}

output "public_ip" {
  description = "Public IP of the instance"
  value       = aws_instance.server.public_ip
}

output "private_key_file" {
  description = "Path to the generated private key file"
  value       = local_sensitive_file.private_key.filename
}
