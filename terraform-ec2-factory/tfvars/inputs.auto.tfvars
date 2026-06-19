aws_region = "ap-south-1"

default_tags = {
  "Environment" = "Test"
  "Project"     = "HOS"
}

servers = {
  "web-server-01" = {
    ami            = "ami-006f82a1d5a27da54"
    instance_type  = "t3.medium"
    subnet_id      = "subnet-01962d22801ff2bf6"
    volume_size    = 50
    volume_type    = "gp3"
    user_data_file = "userdata/web_server.sh"
    username       = "deployer"
    server_name    = "custom-web-server-name"
    sg_name        = "custom-web-sg"
    iam_role_name  = "custom-web-role"
    key_pair_name  = "custom-web-key"
    tags = {
      "Role" = "Web"
    }
  }
}
