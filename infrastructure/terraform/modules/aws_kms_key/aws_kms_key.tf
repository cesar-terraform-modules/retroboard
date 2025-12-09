resource "aws_kms_key" "this" {
  description         = var.description
  enable_key_rotation = var.enable_key_rotation
  tags                = var.tags
}



