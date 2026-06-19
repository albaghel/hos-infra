# Terraform EC2 Factory

A robust, enterprise-grade Terraform framework for provisioning custom EC2 instances on AWS with safety safeguards to prevent accidental infrastructure destruction.

---

## 📋 Features

- Uses a reusable internal `ec2` module.
- Driven entirely by configuration maps defined in `.tfvars` files.
- **Dynamic Security**: Automatically generates a unique SSH Key Pair, Security Group, and IAM Role per instance.
- **Automated Keys**: Automatically downloads and saves the `.pem` SSH private key directly into your workspace.
- **Accidental Destroy Safeguard**: Integrates `prevent_destroy = true` on critical infrastructure components (such as the Security Group) to prevent unintended teardowns.

---

## 🛠️ Prerequisites & Installation

To run this repository locally, you need to install both the **AWS CLI** and **Terraform**.

### 1. Install AWS CLI (Linux / Debian / Ubuntu)
```bash
# Download the installation zip file
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"

# Unzip the package (install unzip first if you don't have it: sudo apt install unzip)
unzip awscliv2.zip

# Run the installer
sudo ./aws/install

# Verify the installation
aws --version
```

### 2. Install Terraform (Ubuntu / Debian)
```bash
# Ensure system is up to date and install gnupg/software-properties-common
sudo apt-get update && sudo apt-get install -y gnupg software-properties-common

# Install the HashiCorp GPG key
wget -O- https://apt.releases.hashicorp.com/gpg | gpg --dearmor | sudo tee /usr/share/keyrings/hashicorp-archive-keyring.gpg > /dev/null

# Add the official HashiCorp Linux repository
echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list

# Update package lists and install Terraform
sudo apt-get update && sudo apt-get install terraform

# Verify the installation
terraform -version
```

### 3. Configure AWS CLI Credentials
Before deploying, authenticate your terminal with your AWS account credentials:
```bash
aws configure
```
You will be prompted for your **AWS Access Key ID**, **AWS Secret Access Key**, and **Default region name** (e.g., `ap-south-1`).

---

## 🚀 Usage & Deployment Guide

### 1. Define Your Servers
Open `tfvars/inputs.auto.tfvars` and add/configure instances under the `servers` map. Make sure you set a `username` if you want a custom OS user created:

```terraform
servers = {
  "web-server-01" = {
    ami            = "ami-006f82a1d5a27da54"
    instance_type  = "t3.medium"
    subnet_id      = "subnet-01962d22801ff2bf6"
    volume_size    = 50
    volume_type    = "gp3"
    user_data_file = "userdata/web_server.sh"
    username       = "deployer"  # Custom username
    
    server_name    = "custom-web-server-name"
    sg_name        = "custom-web-sg"
    iam_role_name  = "custom-web-role"
    key_pair_name  = "custom-web-key"
  }
}
```

### 2. Deploy Everything
Initialize Terraform and apply the configurations:
```bash
# Initialize and fetch modules
terraform init -upgrade

# Run apply (this will prompt you dynamically for the OS user password)
terraform apply -var-file=tfvars/inputs.auto.tfvars
```

If you wish to auto-approve the execution plan and pass a pre-defined password:
```bash
terraform apply -var-file=tfvars/inputs.auto.tfvars -var="user_password=your_secure_password" --auto-approve
```

---

## 🛑 How to Destroy Resources

Because this architecture enforces `prevent_destroy = true` on the Security Group, you must follow specific strategies based on what you want to destroy.

> [!IMPORTANT]
> **Why does `terraform destroy` fail by default?**
> The `aws_security_group` has a lifecycle safety block `prevent_destroy = true` enabled. Attempting a standard `terraform destroy` will exit with an error to protect this resource.

---

### Scenario A: Destroy only the EC2 Instance (Keep Security Group)
If you want to terminate the EC2 instance, delete the IAM Roles, and clean up SSH keys, but **keep the Security Group active in AWS**, run these commands:

1. **Remove the Security Group from Terraform's Tracking:**
   This removes the group from your local state file. It stays alive in AWS, but Terraform will no longer attempt to destroy it.
   ```bash
   terraform state rm 'module.ec2["web-server-01"].aws_security_group.this[0]'
   ```

2. **Update the Configuration File:**
   Open `tfvars/inputs.auto.tfvars` and remove the server from the `servers` map (setting it to `servers = {}`).

3. **Apply the Changes:**
   Execute apply. Since the server is removed from the configuration, Terraform will destroy the EC2 instance, SSH keys, and IAM roles, leaving the Security Group untouched in AWS.
   ```bash
   terraform apply -var-file=tfvars/inputs.auto.tfvars -var="user_password=dummy" --auto-approve
   ```

---

### Scenario B: Destroy only the Security Group (Keep Instance)
> [!WARNING]
> In AWS, you cannot delete a Security Group that is actively attached to a running EC2 instance. 

If you want to disassociate the Security Group and delete it but keep the instance:
1. **Remove the Security Group from state tracking** so Terraform ignores it:
   ```bash
   terraform state rm 'module.ec2["web-server-01"].aws_security_group.this[0]'
   ```
2. Manually log into your AWS Console (or use AWS CLI) to detach it from the running EC2 instance and delete the group.

---

### Scenario C: Destroy EVERYTHING (Instance + Security Group)
To completely wipe out all infrastructure including the Security Group:


1. **Temporarily Disable the Safety Safeguard:**
   Open `modules/ec2/main.tf` and find the `aws_security_group` resource (around line 66). Change the lifecycle attribute from `true` to `false`:
   ```terraform
   lifecycle {
     prevent_destroy = false
   }
   ```

2. **Execute Destroy:**
   Run the destroy command, passing the variables file:
   ```bash
   terraform destroy -var-file=tfvars/inputs.auto.tfvars -var="user_password=dummy" --auto-approve
   ```

1. Open the file: `tfvars/inputs.auto.tfvars`
2. You will see a `servers = { ... }` block. Copy an existing server block and paste it below, giving it a unique name (e.g., `"my-new-server"`).
3. Update the `ami`, `instance_type`, and `subnet_id` to match what you need.
4. If your server needs a startup script, put your script inside the `userdata/` folder and add `user_data_file = "userdata/your_script.sh"` to your block.
5. In your terminal, run: `terraform plan -var-file="tfvars/inputs.auto.tfvars"`. Terraform will halt and prompt you for a `user_password`. Type the password you want for your custom user.
6. If it looks good, run: `terraform apply -var-file="tfvars/inputs.auto.tfvars"`. You will be prompted for the password again to confirm the deployment.

Once finished, Terraform will automatically download your `.pem` SSH key into the main folder and print your Server IP on the screen. If you specified a custom `username`, you can now SSH into the instance using either your `.pem` key or the password you provided!
