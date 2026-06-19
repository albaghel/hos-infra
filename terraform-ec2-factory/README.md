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

## Developer Onboarding Guide

Welcome! You can use this repository to easily request an EC2 instance. You do not need to know how to write Terraform.

### Local Prerequisites

Before you begin, ensure you have the necessary tools installed and configured:

1. **Install Terraform**: Download and install [Terraform](https://developer.hashicorp.com/terraform/install).
2. **Install AWS CLI**: Download and install the [AWS CLI](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html).
3. **Configure AWS Credentials**: Log in using your enterprise SSO or run `aws configure`.

Verify your installation:
```bash
terraform version
aws sts get-caller-identity
```

### Deployment Workflow

**To request a new instance:**

1. Open the file: `tfvars/inputs.auto.tfvars`
2. You will see a `servers = { ... }` block. Copy an existing server block and paste it below, giving it a unique name (e.g., `"my-new-server"`).
3. Update the `ami`, `instance_type`, and `subnet_id` to match what you need.
4. If your server needs a startup script, put your script inside the `userdata/` folder and add `user_data_file = "userdata/your_script.sh"` to your block.
5. In your terminal, run: `terraform plan -var-file="tfvars/inputs.auto.tfvars"`.
6. If it looks good, run: `terraform apply -var-file="tfvars/inputs.auto.tfvars"`.

Once finished, Terraform will automatically download your `.pem` SSH key into the main folder and print your Server IP on the screen so you can log in immediately.
