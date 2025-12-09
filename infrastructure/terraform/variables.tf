variable "region" {
  description = "AWS region in which the project needs to be setup (us-east-1, ca-west-1, eu-west-3, etc)"
}

variable "rds_master_password_c5d6f2e4-663a-4cb7-aa07-02f8f5058a69" {
  default     = "NotifDbP@ssw0rd!"
  description = "Password for the master DB user"
  type        = string
  nullable    = false
  sensitive   = true
}

