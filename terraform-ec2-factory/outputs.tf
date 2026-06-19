output "instances" {
  description = "Map of all provisioned EC2 instances and their associated data"
  value = {
    for k, v in module.ec2 : k => {
      instance_id     = v.instance_id
      private_ip      = v.private_ip
      public_ip       = v.public_ip
      private_key_file = v.private_key_file
    }
  }
}