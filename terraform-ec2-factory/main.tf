locals {
  # Build a map of user data content based on the provided file path.
  user_data_contents = {
    for k, v in var.servers : k => v.user_data_file != null && v.user_data_file != "" ? file("${path.module}/${v.user_data_file}") : null
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
  
  tags          = each.value.tags
}
