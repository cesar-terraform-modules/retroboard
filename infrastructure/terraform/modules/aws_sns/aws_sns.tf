resource "aws_sns_topic" "this" {
  name                                     = var.topic_name
  display_name                             = var.display_name
  delivery_policy                          = var.delivery_policy
  application_success_feedback_role_arn    = var.application_success_feedback_role_arn
  application_success_feedback_sample_rate = var.application_success_feedback_sample_rate
  application_failure_feedback_role_arn    = var.application_failure_feedback_role_arn
  http_success_feedback_role_arn           = var.http_success_feedback_role_arn
  http_success_feedback_sample_rate        = var.http_success_feedback_sample_rate
  http_failure_feedback_role_arn           = var.http_failure_feedback_role_arn
  kms_master_key_id                        = var.use_custom_kms_key_for_encryption ? aws_kms_key.custom_sns_kms_key[0].key_id : null
  signature_version                        = var.signature_version
  tracing_config                           = var.tracing_config
  fifo_topic                               = var.fifo_topic
  content_based_deduplication              = var.content_based_deduplication
  lambda_success_feedback_role_arn         = var.lambda_success_feedback_role_arn
  lambda_success_feedback_sample_rate      = var.lambda_success_feedback_sample_rate
  lambda_failure_feedback_role_arn         = var.lambda_failure_feedback_role_arn
  sqs_success_feedback_role_arn            = var.sqs_success_feedback_role_arn
  sqs_success_feedback_sample_rate         = var.sqs_success_feedback_sample_rate
  sqs_failure_feedback_role_arn            = var.sqs_failure_feedback_role_arn
  firehose_success_feedback_role_arn       = var.firehose_success_feedback_role_arn
  firehose_success_feedback_sample_rate    = var.firehose_success_feedback_sample_rate
  firehose_failure_feedback_role_arn       = var.firehose_failure_feedback_role_arn
  tags                                     = var.tags

}

resource "aws_sns_topic_policy" "allow_access" {
  count  = var.topic_policy == "" ? 0 : 1
  arn    = aws_sns_topic.this.arn
  policy = var.topic_policy
}


resource "aws_kms_key" "custom_sns_kms_key" {
  count               = var.use_custom_kms_key_for_encryption ? 1 : 0
  description         = "Custom KMS key for SNS encryption"
  enable_key_rotation = true
}

resource "aws_kms_alias" "a" {
  count         = var.use_custom_kms_key_for_encryption ? 1 : 0
  name          = "alias/sns-${replace(var.topic_name, "/[^0-9A-Za-z_/-]/", "")}"
  target_key_id = aws_kms_key.custom_sns_kms_key[0].key_id
}

resource "aws_kms_key_policy" "custom_sns_key_policy" {
  count  = var.use_custom_kms_key_for_encryption ? 1 : 0
  key_id = aws_kms_key.custom_sns_kms_key[0].id
  policy = data.aws_iam_policy_document.custom_sns_key_policy.json
}

data "aws_iam_policy_document" "custom_sns_key_policy" {
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
      identifiers = ["sns.amazonaws.com"]
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



