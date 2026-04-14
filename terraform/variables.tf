
################################################################################

variable "vpc_id" { type = string }

variable "private_subnet_ids" { type = list(string) }

variable "public_subnet_ids" { type = list(string) }

variable "ecr_api_url" { type = string }

variable "ecr_app_url" { type = string }

variable "ecr_email_summary_url" { type = string }

variable "ecr_notification_url" { type = string }

variable "ses_from_email" { type = string }

variable "aws_account_id" { type = string }

variable "environment" {
  type    = string
  default = "dev"
}

