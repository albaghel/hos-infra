# ==============================================================
# Local Values — Centralised Configuration
# ==============================================================
# This file has TWO responsibilities:
#
#  1. Parse servers.yaml and normalise each entry into a
#     consistent map structure consumed by for_each in main.tf.
#
#  2. Hold all common infrastructure references (VPC, subnet,
#     security groups, etc.) so they are defined in exactly one
#     place.  An ops engineer updates this file once when setting
#     up a new environment; developers never touch it.
# ==============================================================

locals {

  # ------------------------------------------------------------
  # YAML Parsing
  # ------------------------------------------------------------
  # Read and decode servers.yaml into a Terraform value.
  # path.module resolves to the directory containing this file,
  # so the path is always correct regardless of where terraform
  # is invoked from.
  # ------------------------------------------------------------
  _raw_config = yamldecode(file("${path.module}/servers.yaml"))

  # Convert the YAML list to a map keyed by instance name.
  # for_each requires a map (or set); name is used as the
  # Terraform resource address, e.g. module.ec2["jenkins"].
  #
  # try() provides safe defaults for every optional YAML field
  # so adding new optional fields never breaks existing entries.
  instances = {
    for inst in local._raw_config.instances :
    inst.name => {
      instance_type       = inst.instance_type
      volume_size         = inst.volume_size
      ami_type            = try(inst.ami_type, null)
      ami_id_override     = try(inst.ami_id, null)
      associate_public_ip = try(inst.associate_public_ip, true)
      user_data_file      = try(inst.user_data_file, null)
      additional_volumes  = try(inst.additional_volumes, [])
    }
  }

  # ------------------------------------------------------------
  # Common Infrastructure References
  # ------------------------------------------------------------
  # Sourced from input variables — set values in terraform.tfvars.
  # ------------------------------------------------------------

  vpc_id               = var.vpc_id
  subnet_id            = var.subnet_id
  security_group_ids   = var.security_group_ids
  key_name             = var.key_name
  iam_instance_profile = var.iam_instance_profile

  # ------------------------------------------------------------
  # AMI Resolution Map
  # ------------------------------------------------------------
  # Maps the ami_type string from servers.yaml to the actual AMI
  # ID returned by the data sources defined in main.tf.
  #
  # To add a new OS (e.g., "debian"):
  #   1. Add a data "aws_ami" "debian" block in main.tf.
  #   2. Add  debian = data.aws_ami.debian.id  here.
  #   3. Developers can then use  ami_type: debian  in servers.yaml.
  # ------------------------------------------------------------
  ami_map = {
    ubuntu      = data.aws_ami.ubuntu.id
    amazonlinux = data.aws_ami.amazonlinux.id
  }
}
