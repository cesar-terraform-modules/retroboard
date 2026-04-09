
################################################################################

variable "project" { type = string }

variable "environment" { type = string }

variable "aws_region" { type = string }

variable "aws_account_id" { type = string }

variable "ses_sender_email" { type = string }

variable "slack_webhook_url" { type = string }

variable "vpc_id" { type = string }

variable "private_subnet_ids" { type = string }

variable "public_subnet_ids" { type = string }

