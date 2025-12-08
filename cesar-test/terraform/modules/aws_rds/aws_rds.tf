# aws resource for rds cluster creation 
resource "aws_rds_cluster" "this" {
  cluster_identifier = var.cluster_identifier

  # engine settings
  engine         = var.rds_engine
  engine_version = var.rds_engine_version
  engine_mode    = var.rds_engine_mode

  # database settings
  database_name        = var.rds_database_name
  master_username      = var.rds_master_username
  master_password      = var.rds_master_password
  db_subnet_group_name = var.rds_db_subnet_group_name

  # encryption settings
  storage_encrypted       = var.rds_storage_encrypted
  backup_retention_period = var.rds_backup_retention_period
  kms_key_id              = var.use_custom_kms_key_for_encryption ? aws_kms_key.custom_rds_kms_key[0].arn : null

  # cluster settings
  availability_zones           = var.rds_availability_zones
  preferred_backup_window      = var.rds_preferred_backup_window
  preferred_maintenance_window = var.rds_preferred_maintenance_window

  # scaling configuration
  dynamic "scaling_configuration" {
    for_each = var.rds_auto_pause ? [1] : []
    content {
      auto_pause               = var.rds_auto_pause
      max_capacity             = var.rds_max_capacity
      min_capacity             = var.rds_min_capacity
      seconds_until_auto_pause = 300
    }
  }
  vpc_security_group_ids = var.security_groups
  tags                   = var.tags
}

resource "aws_kms_key" "custom_rds_kms_key" {
  count               = var.use_custom_kms_key_for_encryption ? 1 : 0
  description         = "Custom KMS key for RDS encryption"
  enable_key_rotation = true
}

resource "aws_kms_alias" "a" {
  count         = var.use_custom_kms_key_for_encryption ? 1 : 0
  name          = "alias/sns-${aws_rds_cluster.this.cluster_identifier}"
  target_key_id = aws_kms_key.custom_rds_kms_key[0].key_id
}

resource "aws_kms_key_policy" "custom_rds_key_policy" {
  count  = var.use_custom_kms_key_for_encryption ? 1 : 0
  key_id = aws_kms_key.custom_rds_kms_key[0].id
  policy = data.aws_iam_policy_document.custom_rds_key_policy.json
}

data "aws_iam_policy_document" "custom_rds_key_policy" {
  statement {
    actions = [
      "kms:DescribeKey",
      "kms:ReEncrypt*",
      "kms:Encrypt",
      "kms:Decrypt",
      "kms:GenerateDataKey*"
    ]
    effect    = "Allow"
    resources = ["*"]
    principals {
      type        = "Service"
      identifiers = ["rds.amazonaws.com"]
    }
    condition {
      test     = "StringEquals"
      variable = "kms:ViaService"
      values   = ["rds.${var.region}.amazonaws.com"]
    }
  }
  # Allows key management using AWS IAM
  statement {
    actions = [
      "kms:*"
    ]
    effect    = "Allow"
    resources = ["*"]
    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"]
    }
  }
}

data "aws_caller_identity" "current" {}


