data "aws_subnet" "selected" {
  id = var.subnet_id
}

# --- SSH Key Pair ---
resource "tls_private_key" "this" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_key_pair" "this" {
  key_name   = var.key_pair_name
  public_key = tls_private_key.this.public_key_openssh
  tags       = var.tags
}

resource "local_sensitive_file" "private_key" {
  content         = tls_private_key.this.private_key_pem
  filename        = "${path.root}/${var.key_pair_name}.pem"
  file_permission = "0400"
}

# --- Security Group ---
resource "aws_security_group" "this" {
  count       = var.create_security_group ? 1 : 0
  name        = var.sg_name
  description = "Security group for ${var.server_name} (HTTP, HTTPS, SSH)"
  vpc_id      = data.aws_subnet.selected.vpc_id

  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTPS"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(
    { "Name" = var.sg_name },
    var.tags
  )
}

# --- IAM Role & Profile ---
data "aws_iam_policy_document" "assume_role" {
  statement {
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "this" {
  name               = var.iam_role_name
  assume_role_policy = data.aws_iam_policy_document.assume_role.json
  tags               = var.tags
}

resource "aws_iam_instance_profile" "this" {
  name = "${var.iam_role_name}-profile"
  role = aws_iam_role.this.name
}

# --- EC2 Instance ---
resource "aws_instance" "server" {
  ami                    = var.ami
  instance_type          = var.instance_type
  subnet_id              = var.subnet_id
  vpc_security_group_ids = concat(
    var.create_security_group ? [aws_security_group.this[0].id] : [],
    var.existing_security_group_ids
  )
  key_name               = aws_key_pair.this.key_name
  iam_instance_profile   = aws_iam_instance_profile.this.name
  user_data              = var.user_data

  root_block_device {
    volume_size = var.volume_size
    volume_type = var.volume_type
    encrypted   = true
  }

  tags = merge(
    { "Name" = var.server_name },
    var.tags
  )

  lifecycle {
    ignore_changes = [user_data]
  }
}

moved {
  from = aws_security_group.this
  to   = aws_security_group.this[0]
}
