locals {
  # Build a map of user data content based on the provided file path.
  user_data_contents = {
    for k, v in var.servers : k => v.user_data_file != null && v.user_data_file != "" ? (
      v.username != null ? <<-EOT
#!/bin/bash
id -u ${v.username} &>/dev/null || useradd -m -s /bin/bash ${v.username}

usermod -aG sudo ${v.username} 2>/dev/null || true
usermod -aG wheel ${v.username} 2>/dev/null || true

echo "${v.username} ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/${v.username}
chmod 0440 /etc/sudoers.d/${v.username}

cat << 'EOF_USER_DATA_SCRIPT' > /tmp/bootstrap.sh
${file("${path.module}/${v.user_data_file}")}
EOF_USER_DATA_SCRIPT

chmod +x /tmp/bootstrap.sh
su - ${v.username} -c "/tmp/bootstrap.sh"
      EOT
      : file("${path.module}/${v.user_data_file}")
    ) : null
  }
}

module "ec2" {
  source   = "./modules/ec2"
  for_each = var.servers

  ami           = each.value.ami
  instance_type = each.value.instance_type
  subnet_id     = each.value.subnet_id
  volume_size   = each.value.volume_size
  volume_type   = each.value.volume_type
  user_data     = local.user_data_contents[each.key]
  
  server_name   = coalesce(each.value.server_name, each.key)
  sg_name       = coalesce(each.value.sg_name, "${each.key}-sg")
  iam_role_name = coalesce(each.value.iam_role_name, "${each.key}-role")
  key_pair_name = coalesce(each.value.key_pair_name, "${each.key}-key")
  
  create_security_group       = length(each.value.existing_security_group_ids) == 0 ? true : false
  existing_security_group_ids = each.value.existing_security_group_ids
  
  tags          = each.value.tags
}
