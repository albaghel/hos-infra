# Terraform EC2 Factory

A robust, enterprise-grade Terraform framework for provisioning custom EC2 instances on AWS.

## Features

- Uses a reusable internal `ec2` module.
- Driven entirely by configuration maps defined in `.tfvars` files.
- **Dynamic Security**: Automatically generates a unique SSH Key Pair, Security Group, and IAM Role per instance.
- **Automated Keys**: Automatically downloads and saves the `.pem` SSH private key directly into your workspace.
- **Custom Naming**: Allows you to explicitly define names for your Server, Security Group, IAM Role, and Key Pair.
- Automatically handles dynamic User Data injection via local shell scripts.

## Usage Guide

### 1. Configure your Servers

Open the `tfvars/inputs.auto.tfvars` file and define your instances in the `servers` map.

```terraform
servers = {
  "web-server-01" = {
    ami            = "ami-0e38835daf6b8a2b9"
    instance_type  = "t3.medium"
    subnet_id      = "subnet-01962d22801ff2bf6"
    volume_size    = 50
    user_data_file = "userdata/web_server.sh"
    
    # Custom Naming (Optional)
    server_name    = "custom-web-server"
    sg_name        = "custom-web-sg"
    iam_role_name  = "custom-web-role"
    key_pair_name  = "custom-web-key"
  }
}
```

### 2. Deploy the Infrastructure

Because your variables file is located inside a subdirectory (`tfvars/`), you **must** explicitly pass the `-var-file` flag with your Terraform commands.

Initialize the working directory:
```bash
terraform init -upgrade
```

Preview the changes:
```bash
terraform plan -var-file="tfvars/inputs.auto.tfvars"
```

Apply the changes to deploy:
```bash
terraform apply -var-file="tfvars/inputs.auto.tfvars" --auto-approve
```

### 3. Connect to your Instance

Once the deployment completes, Terraform will automatically save your private key in the root directory (e.g., `./custom-web-key.pem`) and output the public IP of the instance.

Connect using SSH:
```bash
ssh -i ./custom-web-key.pem ubuntu@<PUBLIC_IP_FROM_OUTPUT>
```
*(Note: Use `ubuntu` for Ubuntu AMIs, `ec2-user` for Amazon Linux, or `admin` for Debian)*

## Directory Structure

- `main.tf`, `variables.tf`, `outputs.tf`: Root module configuration.
- `modules/ec2`: The reusable EC2 instance module.
- `userdata/`: Store your bash scripts here for user data injection.
- `tfvars/`: Store your environment specific variable files here.
