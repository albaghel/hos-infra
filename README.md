# AWS EC2 Terraform — YAML-Driven Provisioning

Production-grade Terraform project for AWS EC2 provisioning. Developers add, modify, or remove EC2 instances by editing a single YAML file — no Terraform code changes required.

---

## How It Works

```
servers.yaml  ──►  locals.tf (parse + normalise)
                       │
               data sources (resolve latest AMIs)   ← only when ami_type used
                       │
              module.ec2[*] via for_each
                       │
               aws_instance per entry
```

The YAML is parsed at plan time. Adding a new server entry to `servers.yaml` and running `terraform apply` is all that is needed.

---

## Project Structure

```
terraform/
│
├── main.tf          # AMI data sources + module.ec2 for_each call
├── provider.tf      # AWS provider + default tags
├── variables.tf     # Region, project, environment, VPC, subnet, SG, key
├── locals.tf        # YAML parsing + infrastructure variable wiring
├── outputs.tf       # Instance IDs, IPs, ARNs
├── versions.tf      # Terraform >= 1.5, AWS ~> 5.0
├── servers.yaml     # ← THE ONLY FILE DEVELOPERS EDIT
├── terraform.tfvars # ← Ops engineer fills once (not committed)
│
├── scripts/
│   └── jenkins.sh   # Example bootstrap script (user_data)
│
└── modules/
    └── ec2/
        ├── main.tf       # aws_instance resource (IMDSv2, gp3, monitoring)
        ├── variables.tf  # Module inputs with validation
        └── outputs.tf    # Instance ID, IPs, ARN, AZ
```

---

## Prerequisites

| Tool      | Minimum Version | Notes                        |
|-----------|-----------------|------------------------------|
| Terraform | 1.5.0           | `brew install terraform`     |
| AWS CLI   | 2.x             | For credential configuration |

AWS credentials must be configured before running any Terraform command:

```bash
# Option A — named profile
export AWS_PROFILE=my-profile

# Option B — environment variables
export AWS_ACCESS_KEY_ID=...
export AWS_SECRET_ACCESS_KEY=...
export AWS_DEFAULT_REGION=us-east-1

# Option C — IAM role (EC2 / ECS / GitHub Actions OIDC)
# No manual credential setup required.
```

---

## One-Time Setup (Ops Engineers)

Before developers can use `servers.yaml`, create `terraform/terraform.tfvars` with the real infrastructure values for the target environment. This file is not committed to source control.

```hcl
# terraform/terraform.tfvars

aws_region  = "us-east-1"          # AWS region to deploy into
project     = "my-project"         # Applied to all resource Name tags
environment = "dev"                 # dev | staging | prod

vpc_id             = "vpc-0abc123def456789a"    # VPC containing the subnet
subnet_id          = "subnet-0abc123def456789a" # Subnet for all instances
security_group_ids = ["sg-0abc123def456789a"]   # One or more SG IDs
key_name           = "my-ec2-key-pair"          # EC2 key pair name (or omit for SSM-only)
iam_instance_profile = "ec2-ssm-instance-profile" # IAM profile (or omit if none)
```

These values are shared across all instances. Set once per environment; developers never touch this file.

### How to find these values

| Variable | Where to find it |
|---|---|
| `vpc_id` | AWS Console → VPC → Your VPCs → VPC ID column |
| `subnet_id` | AWS Console → VPC → Subnets → Subnet ID column |
| `security_group_ids` | AWS Console → EC2 → Security Groups → Security group ID |
| `key_name` | AWS Console → EC2 → Key Pairs → Name column |
| `iam_instance_profile` | AWS Console → IAM → Roles → Instance Profile Name |

---

## Developer Guide

> **Developers only need to edit `terraform/servers.yaml`.** No `.tf` files, no variables, no infrastructure knowledge required.

### Step 1 — Open servers.yaml

```
terraform/servers.yaml
```

### Step 2 — Add, edit, or remove an instance entry

Each entry in the `instances` list becomes one EC2 instance. Minimum required fields:

```yaml
instances:
  - name: my-server
    instance_type: t3.medium
    volume_size: 20
    ami_id: ami-0c02fb55956c7d316    # your specific AMI ID
```

Or use a managed OS image (always resolves to the latest stable version):

```yaml
  - name: my-server
    instance_type: t3.medium
    volume_size: 20
    ami_type: ubuntu
```

### Step 3 — Preview the changes

```bash
cd terraform
terraform plan
```

Terraform shows exactly what will be created, modified, or destroyed — no surprises.

### Step 4 — Apply

```bash
terraform apply
```

Type `yes` when prompted, or use `-auto-approve` in CI.

### Step 5 — Retrieve outputs

```bash
# All instance IDs
terraform output instance_ids

# Specific instance private IP
terraform output -json private_ips | jq '.["my-server"]'

# Full summary table
terraform output instance_summary
```

### Step 6 — Remove an instance

Delete or comment out the entry in `servers.yaml`, then:

```bash
terraform plan    # confirm only that instance is being destroyed
terraform apply
```

---

## servers.yaml Field Reference

### Required Fields

| Field | Type | Description |
|---|---|---|
| `name` | string | Unique instance identifier. Becomes the AWS `Name` tag and Terraform resource key. Lowercase letters, numbers, hyphens only. Cannot start or end with a hyphen. |
| `instance_type` | string | EC2 instance type. Examples: `t3.micro`, `t3.medium`, `m5.xlarge`. |
| `volume_size` | number | Root EBS volume size in GB. Minimum: 8. Maximum: 16384. |

**One of the following AMI fields is required per instance:**

| Field | Type | Description |
|---|---|---|
| `ami_id` | string | Direct AMI ID. Use when you need a specific, pinned, or golden image. Format: `ami-` followed by 8–17 hex characters. Example: `ami-0c02fb55956c7d316`. |
| `ami_type` | string | Managed OS label. Terraform resolves this to the latest stable AMI automatically. See [Supported AMI Types](#supported-ami-types). |

> If both are set, `ami_id` takes precedence.

### Optional Fields

| Field | Type | Default | Description |
|---|---|---|---|
| `associate_public_ip` | bool | `true` | Assign a public IPv4 address. Set to `false` for private-only instances (behind a load balancer, bastion, etc.). |
| `user_data_file` | string | `null` | Path to a bootstrap shell script relative to `terraform/`. Runs once on first boot. Example: `scripts/jenkins.sh`. |
| `additional_volumes` | list | `[]` | Extra EBS data volumes. See [Additional Volumes](#additional-volumes). |

### Supported AMI Types

| `ami_type` | OS | Publisher | Resolution |
|---|---|---|---|
| `ubuntu` | Ubuntu 22.04 LTS | Canonical | Latest HVM x86_64 image |
| `amazonlinux` | Amazon Linux 2 | Amazon | Latest HVM x86_64 gp2 image |

> AMI IDs are region-specific and resolved automatically — no manual ID lookup needed when using `ami_type`.

### Additional Volumes

```yaml
additional_volumes:
  - device_name: /dev/xvdb      # (required) Linux device path
    volume_size: 100             # (required) Size in GB (1–16384)
    volume_type: gp3             # (optional) default: gp3
```

Supported `volume_type` values: `gp3` (recommended), `gp2`, `io1`, `io2`, `sc1`, `st1`, `standard`

All additional volumes are encrypted at rest and tagged automatically.

### Supported Volume Types

| Type | Use Case |
|---|---|
| `gp3` | General purpose — recommended for most workloads |
| `gp2` | Legacy general purpose |
| `io1` / `io2` | High IOPS — databases, latency-sensitive apps |
| `sc1` | Cold HDD — infrequent access, low cost |
| `st1` | Throughput HDD — big data, log processing |

---

## Full servers.yaml Example

```yaml
instances:

  # Minimal — private instance using direct AMI ID
  - name: instance-1
    instance_type: t3.micro
    volume_size: 20
    ami_id: ami-0c02fb55956c7d316

  # Using managed OS label (resolves latest Ubuntu automatically)
  - name: instance-2
    instance_type: t3.medium
    volume_size: 30
    ami_type: ubuntu

  # Private-only instance (behind load balancer)
  - name: instance-3
    instance_type: t3.large
    volume_size: 50
    ami_id: ami-0c02fb55956c7d316
    associate_public_ip: false

  # Full configuration — extra volumes + bootstrap script
  - name: instance-4
    instance_type: t3.xlarge
    volume_size: 100
    ami_type: amazonlinux
    associate_public_ip: true
    user_data_file: scripts/jenkins.sh
    additional_volumes:
      - device_name: /dev/xvdb
        volume_size: 200
        volume_type: gp3
      - device_name: /dev/xvdc
        volume_size: 100
        volume_type: io2
```

---

## Adding a Bootstrap Script

1. Create a shell script in `terraform/scripts/`:

```bash
#!/usr/bin/env bash
# terraform/scripts/my-app.sh
set -euo pipefail
yum install -y nginx
systemctl enable --now nginx
```

2. Reference it in `servers.yaml`:

```yaml
- name: web
  instance_type: t3.medium
  volume_size: 20
  ami_type: amazonlinux
  user_data_file: scripts/my-app.sh
```

The script runs once on first boot. Changes to the script do **not** trigger instance replacement — use SSM Run Command or bake a new AMI to push script changes to running instances.

---

## Adding a New AMI Type

To support a new OS family via `ami_type`:

1. Add a `data "aws_ami"` block in `terraform/main.tf`:

```hcl
data "aws_ami" "debian" {
  most_recent = true
  owners      = ["136693071363"] # Debian official

  filter { name = "name";                values = ["debian-12-amd64-*"] }
  filter { name = "virtualization-type"; values = ["hvm"] }
}
```

2. Add the mapping in `terraform/locals.tf`:

```hcl
ami_map = {
  ubuntu      = data.aws_ami.ubuntu.id
  amazonlinux = data.aws_ami.amazonlinux.id
  debian      = data.aws_ami.debian.id   # ← new
}
```

Developers can then use `ami_type: debian` in `servers.yaml`.

---

## Terraform Commands Reference

```bash
# Initialise — download providers and modules (once per workspace)
terraform init

# Validate syntax and configuration
terraform validate

# Preview changes without applying
terraform plan

# Apply changes
terraform apply

# Apply without interactive prompt (CI/CD)
terraform apply -auto-approve

# Target a single instance
terraform apply -target='module.ec2["instance-1"]'

# Destroy all resources
terraform destroy

# Show current state
terraform show

# List all resources in state
terraform state list
```

---

## Security Hardening Applied

| Control | Setting |
|---|---|
| IMDSv2 | `http_tokens = required` — blocks SSRF credential theft via metadata endpoint |
| EBS encryption | All root and additional volumes encrypted at rest |
| CloudWatch monitoring | Detailed (1-minute granularity) |
| EBS-optimised I/O | Enabled on all instances |
| AMI drift prevention | `ignore_changes = [ami]` — prevents unintended instance replacement on plan |
| Provider default tags | `Project`, `Environment`, `ManagedBy` applied to all resources |
| Public IP default | Controlled per-instance; explicit opt-out available via `associate_public_ip: false` |

---

## Remote State (Recommended for Teams)

Add a backend block to `terraform/versions.tf` before the first `terraform apply`:

```hcl
terraform {
  backend "s3" {
    bucket         = "my-terraform-state"
    key            = "ec2/terraform.tfstate"
    region         = "us-east-1"
    encrypt        = true
    dynamodb_table = "terraform-state-lock"
  }
}
```

Run `terraform init` again after adding the backend to migrate local state to S3.

---

## Variable Reference (terraform.tfvars)

| Variable | Type | Required | Description |
|---|---|---|---|
| `aws_region` | string | yes | AWS region. Example: `us-east-1`. |
| `project` | string | yes | Project name, 1–64 chars. Applied to all Name tags. |
| `environment` | string | yes | One of: `dev`, `staging`, `prod`. |
| `vpc_id` | string | yes | VPC ID. Format: `vpc-` + 8–17 hex chars. |
| `subnet_id` | string | yes | Subnet ID. Format: `subnet-` + 8–17 hex chars. |
| `security_group_ids` | list(string) | yes | At least one SG ID. Format: `sg-` + 8–17 hex chars. |
| `key_name` | string | no | EC2 key pair name. Omit to use SSM Session Manager only. |
| `iam_instance_profile` | string | no | IAM instance profile name. Omit to launch without a profile. |
