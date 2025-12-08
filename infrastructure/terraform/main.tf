module "stackgen_0bc07a7a-dc4c-4e15-aa97-59f074a8472c" {
  source    = "./modules/aws_iam_role_policy"
  name      = "Reader-stackgen_390ec1"
  policy    = "{\n  \"Version\": \"2012-10-17\",\n  \"Statement\": [\n    {\n      \"Sid\": \"4ed341009c774540ac4f8ff1194b396d0\",\n      \"Action\": [\n        \"elasticache:Describe*\"\n      ],\n      \"Effect\": \"Allow\",\n      \"Resource\": [\n        \"${module.stackgen_$${module.stackgen_989395a3-699b-4d6b-affb-cf3160c3922a.arn}.arn}\"\n      ]\n    }\n  ]\n}"
  role      = module.stackgen_ff37b64b-f6c8-44fd-8504-0c8667d0a129.name
  role_type = "Reader"
}

module "stackgen_0c8354fe-d2cb-42f2-a8f2-5fbe7b22763e" {
  source                            = "./modules/aws_rds"
  cluster_identifier                = "slack-alerts-db"
  rds_auto_pause                    = false
  rds_availability_zones            = ["us-east-1a", "us-east-1b"]
  rds_backup_retention_period       = 7
  rds_database_name                 = "retroboard"
  rds_db_subnet_group_name          = "default"
  rds_engine                        = "postgres"
  rds_engine_mode                   = "provisioned"
  rds_engine_version                = "16.4"
  rds_master_password               = var.rds_master_password_c5d6f2e4-663a-4cb7-aa07-02f8f5058a69
  rds_master_username               = "admin"
  rds_max_capacity                  = 2
  rds_min_capacity                  = 1
  rds_preferred_backup_window       = "07:00-09:00"
  rds_preferred_maintenance_window  = "sun:05:00-sun:06:00"
  rds_storage_encrypted             = true
  region                            = var.region
  security_groups                   = null
  tags                              = null
  use_custom_kms_key_for_encryption = false
}

module "stackgen_84149fe3-e117-4edd-9784-e4cf0f456c07" {
  source    = "./modules/aws_iam_role_policy"
  name      = "Reader-stackgen_e8dba1"
  policy    = "{\n  \"Version\": \"2012-10-17\",\n  \"Statement\": [\n    {\n      \"Sid\": \"00d08c90ab3246acab693a1a453059720\",\n      \"Action\": [\n        \"s3:Get*\",\n        \"s3:List*\"\n      ],\n      \"Effect\": \"Allow\",\n      \"Resource\": [\n        \"${module.stackgen_$${module.stackgen_95a75e7e-02cd-463f-831c-99cb01811394.arn}.arn}\",\n        \"${module.stackgen_00d08c90-ab32-46ac-ab69-3a1a45305972.arn}/*\"\n      ]\n    }\n  ]\n}"
  role      = module.stackgen_ff37b64b-f6c8-44fd-8504-0c8667d0a129.name
  role_type = "Reader"
}

module "stackgen_95a75e7e-02cd-463f-831c-99cb01811394" {
  source                       = "./modules/aws_s3"
  block_public_access          = true
  bucket_name                  = "retroboard-slack-alerts-1e9ff482"
  bucket_policy                = ""
  enable_versioning            = true
  enable_website_configuration = false
  sse_algorithm                = "aws:kms"
  tags = {
    service = "slack-alerts"
  }
  website_error_document = "404.html"
  website_index_document = "index.html"
}

module "stackgen_989395a3-699b-4d6b-affb-cf3160c3922a" {
  source                       = "./modules/aws_elasticache"
  access_string                = "on ~*"
  az_mode                      = "single-az"
  cloudwatch_retention_in_days = 30
  cluster_id                   = "slack-alerts-cache"
  enable_redis_log_delivery    = false
  engine                       = "redis"
  family                       = "redis7"
  log_format                   = "json"
  log_type                     = "engine-log"
  node_type                    = "cache.t3.micro"
  num_cache_nodes              = 1
  password                     = ""
  port                         = 6379
  security_group_ids           = null
  subnet_ids                   = null
  tags = {
    service = "slack-alerts"
  }
  use_vpc   = false
  user_id   = "slack-user"
  user_name = "slack-user"
}

module "stackgen_b5fbd00c-4067-4216-9bd1-09ea507f51ae" {
  source    = "./modules/aws_iam_role_policy"
  name      = "Reader-stackgen_c79332"
  policy    = "{\n  \"Version\": \"2012-10-17\",\n  \"Statement\": [\n    {\n      \"Sid\": \"c5d6f2e4663a4cb7aa0702f8f5058a690\",\n      \"Action\": [\n        \"rds:DescribeDBInstances\",\n        \"rds:DescribeDBSnapshots\",\n        \"rds:DescribeDBClusters\",\n        \"rds:DescribeDBSubnetGroups\",\n        \"rds:DescribeDBClusterSnapshots\",\n        \"rds:DescribeDBParameterGroups\",\n        \"rds:DescribeDBParameters\",\n        \"rds:DescribeDBEngineVersions\",\n        \"rds:DescribeEvents\",\n        \"rds:DescribeEventSubscriptions\"\n      ],\n      \"Effect\": \"Allow\",\n      \"Resource\": [\n        \"${module.stackgen_$${module.stackgen_0c8354fe-d2cb-42f2-a8f2-5fbe7b22763e.arn}.arn}\"\n      ]\n    }\n  ]\n}"
  role      = module.stackgen_ff37b64b-f6c8-44fd-8504-0c8667d0a129.name
  role_type = "Reader"
}

module "stackgen_ff37b64b-f6c8-44fd-8504-0c8667d0a129" {
  source                = "./modules/aws_iam_role"
  assume_role_policy    = "{\n\t\t\"Version\": \"2012-10-17\",\n\t\t\"Statement\":{\n\t\t\t\t\"Action\": \"sts:AssumeRole\",\n\t\t\t\t\"Effect\": \"Allow\",\n\t\t\t\t\"Principal\": {\n\t\t\t\t\t\"Service\": \"eks.amazonaws.com\"\n\t\t\t\t}\n\t\t\t}\n\t}"
  description           = null
  force_detach_policies = true
  inline_policy         = []
  max_session_duration  = null
  name                  = "stackgen_91d5be-role"
  path                  = null
  permissions_boundary  = null
  tags                  = null
}

