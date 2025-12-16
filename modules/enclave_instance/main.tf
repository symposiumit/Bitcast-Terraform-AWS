locals {
  name_tag = trimspace(var.name) != "" ? var.name : "${var.project}-nitro-parent"
}

data "aws_ssm_parameter" "al2023" {
  name = "/aws/service/ami-amazon-linux-latest/al2023-ami-kernel-default-x86_64"
}

data "aws_iam_policy_document" "assume" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

data "aws_iam_policy_document" "parent" {
  statement {
    sid    = "NitroOperations"
    effect = "Allow"
    actions = [
      "ec2:DescribeInstances",
      "ec2:DescribeImages",
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents",
      "ssm:GetParameter"
    ]
    resources = ["*"]
  }

  statement {
    sid       = "EnclaveKmsDecrypt"
    effect    = var.kms_key_arn == null ? "Deny" : "Allow"
    actions   = ["kms:Decrypt", "kms:GenerateDataKey"]
    resources = var.kms_key_arn == null ? [] : [var.kms_key_arn]
    condition {
      test     = "Bool"
      variable = "kms:GrantIsForAWSResource"
      values   = ["true"]
    }
  }
}

resource "aws_security_group" "parent" {
  name        = "${var.project}-${local.name_tag}-sg"
  description = "Nitro Enclave parent security group"
  vpc_id      = var.vpc_id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.tags, {
    Name = "${local.name_tag}-sg"
  })
}

resource "aws_security_group_rule" "ssh" {
  for_each          = toset(var.allowed_ingress_cidrs)
  type              = "ingress"
  security_group_id = aws_security_group.parent.id
  protocol          = "tcp"
  from_port         = 22
  to_port           = 22
  cidr_blocks       = [each.value]
  description       = "SSH access"
}

resource "aws_iam_role" "parent" {
  name               = "${var.project}-${local.name_tag}-role"
  assume_role_policy = data.aws_iam_policy_document.assume.json

  tags = merge(var.tags, {
    Name = "${local.name_tag}-role"
  })
}

resource "aws_iam_role_policy" "parent" {
  name   = "${var.project}-${local.name_tag}-policy"
  role   = aws_iam_role.parent.id
  policy = data.aws_iam_policy_document.parent.json
}

data "aws_iam_policy_document" "kms" {
  count = var.kms_key_arn == null ? 0 : 1

  statement {
    sid       = "EnclaveKmsDecrypt"
    effect    = "Allow"
    actions   = ["kms:Decrypt", "kms:GenerateDataKey"]
    resources = [var.kms_key_arn]
    condition {
      test     = "Bool"
      variable = "kms:GrantIsForAWSResource"
      values   = ["true"]
    }
  }
}

resource "aws_iam_role_policy" "kms" {
  count  = var.kms_key_arn == null ? 0 : 1
  name   = "${var.project}-${local.name_tag}-kms"
  role   = aws_iam_role.parent.id
  policy = data.aws_iam_policy_document.kms[0].json
}

resource "aws_iam_instance_profile" "parent" {
  name = "${var.project}-${local.name_tag}-profile"
  role = aws_iam_role.parent.name
}

resource "aws_instance" "parent" {
  ami                    = data.aws_ssm_parameter.al2023.value
  instance_type          = var.instance_type
  subnet_id              = var.subnet_id
  vpc_security_group_ids = [aws_security_group.parent.id]
  iam_instance_profile   = aws_iam_instance_profile.parent.name
  key_name               = var.ssh_key_name

  enclave_options {
    enabled = true
  }

  metadata_options {
    http_endpoint          = "enabled"
    http_tokens            = "required"
    instance_metadata_tags = "enabled"
  }

  user_data = templatefile("${path.module}/user_data.sh", {
    enclave_cpu_count  = var.enclave_cpu_count
    enclave_memory_mib = var.enclave_memory_mib
  })

  tags = merge(var.tags, {
    Name = local.name_tag
  })
}
