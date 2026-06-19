# ==============================================================
# EC2 Instance Module
# ==============================================================
# Creates a single, production-hardened EC2 instance.
#
# Hardening applied:
#   - IMDSv2 enforced (prevents SSRF-based credential theft)
#   - Root and data volumes encrypted at rest
#   - CloudWatch detailed monitoring enabled (1-min granularity)
#   - EBS-optimised I/O bandwidth
#   - ami changes ignored post-deploy (prevents unintended replacement)
# ==============================================================

resource "aws_instance" "this" {

  # --- Core ---
  ami           = var.ami_id
  instance_type = var.instance_type

  # --- Networking ---
  subnet_id                   = var.subnet_id
  vpc_security_group_ids      = var.security_group_ids
  associate_public_ip_address = var.associate_public_ip

  # --- Access ---
  key_name             = var.key_name
  iam_instance_profile = var.iam_instance_profile

  # --- Bootstrap ---
  user_data = var.user_data
  # Do NOT replace the instance when user_data changes; the new
  # script only takes effect on the next boot (or via SSM Run Command).
  user_data_replace_on_change = false

  # --- Observability ---
  # Enables 1-minute CloudWatch metric granularity instead of the
  # default 5-minute interval — essential for autoscaling and alerting.
  monitoring = true

  # --- Performance ---
  # Dedicates network bandwidth for EBS I/O on supported instance types.
  # Most modern types (t3, m5, r5, c5, …) enable this by default;
  # setting it explicitly ensures consistency across instance families.
  ebs_optimized = true

  # --- Root Volume ---
  root_block_device {
    volume_size           = var.volume_size
    volume_type           = "gp3"
    encrypted             = true
    delete_on_termination = true

    tags = {
      Name        = "${var.name}-root"
      Project     = var.project
      Environment = var.environment
      ManagedBy   = "Terraform"
    }
  }

  # --- Additional EBS Volumes (dynamic) ---
  # One ebs_block_device block is rendered per entry in
  # var.additional_volumes.  An empty list produces no blocks.
  dynamic "ebs_block_device" {
    for_each = var.additional_volumes

    content {
      device_name           = ebs_block_device.value.device_name
      volume_size           = ebs_block_device.value.volume_size
      volume_type           = ebs_block_device.value.volume_type
      encrypted             = true
      delete_on_termination = true

      tags = {
        # Strip "/dev/" prefix for a readable volume name tag.
        Name        = "${var.name}-${trimprefix(ebs_block_device.value.device_name, "/dev/")}"
        Project     = var.project
        Environment = var.environment
        ManagedBy   = "Terraform"
      }
    }
  }

  # --- IMDSv2 Enforcement ---
  # http_tokens = "required" forces all metadata requests to use a
  # session-oriented token, blocking SSRF attacks that try to reach
  # http://169.254.169.254 from application code.
  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required"
    http_put_response_hop_limit = 1
  }

  # --- Tags ---
  # The Name tag is set here; Project, Environment, and ManagedBy
  # are also applied via the provider's default_tags block.
  # Explicitly repeating them here ensures volume and ENI sub-resources
  # carry the full tag set even in provider versions that inherit
  # default_tags inconsistently.
  tags = {
    Name        = var.name
    Project     = var.project
    Environment = var.environment
    ManagedBy   = "Terraform"
  }

  lifecycle {
    # Prevent instance replacement when the AMI data source resolves
    # to a newer image on a subsequent plan.  To upgrade the AMI on
    # a running instance, follow the AMI rotation runbook (stop
    # instance → change AMI → start) rather than relying on Terraform
    # destroy-and-recreate, which causes downtime.
    ignore_changes = [ami]
  }
}
