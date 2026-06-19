# ==============================================================
# Main — EC2 Provisioning Entry Point
# ==============================================================
# Developers NEVER edit this file.
# To add, modify, or remove EC2 instances, edit servers.yaml.
#
# Flow:
#   servers.yaml → locals.tf (parsed + normalised)
#              → data sources (AMI IDs resolved)
#              → module.ec2[*] (one instance per YAML entry)
# ==============================================================

# --------------------------------------------------------------
# AMI Data Sources
# --------------------------------------------------------------
# Always resolves to the latest stable AMI for each OS family
# so instances are never pinned to a stale, unpatched image.
#
# AMI IDs are region-specific; using data sources means the same
# configuration works in any AWS region without manual updates.
# --------------------------------------------------------------

data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"] # Canonical — Ubuntu's official AWS publisher account

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  filter {
    name   = "architecture"
    values = ["x86_64"]
  }
}

data "aws_ami" "amazonlinux" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  filter {
    name   = "architecture"
    values = ["x86_64"]
  }
}

# --------------------------------------------------------------
# Runtime Assertion — AMI Type Validation
# --------------------------------------------------------------
# Produces a clear error if any entry in servers.yaml uses an
# ami_type value that is not present in local.ami_map.
# This check runs during both plan and apply (Terraform >= 1.5).
# --------------------------------------------------------------
check "valid_ami_types" {
  assert {
    condition = alltrue([
      for name, inst in local.instances :
      inst.ami_id_override != null || contains(keys(local.ami_map), inst.ami_type)
    ])
    error_message = <<-EOT
      One or more instances in servers.yaml have neither a valid ami_id nor a supported ami_type.
      Supported ami_type values: ${join(", ", keys(local.ami_map))}.
      Alternatively, set ami_id to a specific AMI ID (e.g., ami-0c02fb55956c7d316).
    EOT
  }
}

# --------------------------------------------------------------
# EC2 Instances
# --------------------------------------------------------------
# for_each iterates over the normalised instances map produced
# by locals.tf.  One module instance is created per YAML entry.
# Terraform resource address: module.ec2["<name>"]
# --------------------------------------------------------------

module "ec2" {
  source   = "./modules/ec2"
  for_each = local.instances

  # --- Identity ---
  name        = each.key
  project     = var.project
  environment = var.environment

  # --- Compute ---
  instance_type = each.value.instance_type
  ami_id = (
    each.value.ami_id_override != null
    ? each.value.ami_id_override
    : local.ami_map[each.value.ami_type]
  )

  # --- Storage ---
  volume_size        = each.value.volume_size
  additional_volumes = each.value.additional_volumes

  # --- Networking ---
  subnet_id           = local.subnet_id
  security_group_ids  = local.security_group_ids
  associate_public_ip = each.value.associate_public_ip

  # --- Access ---
  key_name             = local.key_name
  iam_instance_profile = local.iam_instance_profile

  # --- Bootstrap ---
  # Resolve user_data at the root module level so that paths in
  # servers.yaml (e.g., "scripts/jenkins.sh") are relative to
  # the terraform/ directory, which is the natural expectation.
  user_data = (
    each.value.user_data_file != null
    ? file("${path.module}/${each.value.user_data_file}")
    : null
  )
}
