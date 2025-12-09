module "stackgen_01af425f-0bc7-4917-9550-06c220248232" {
  source    = "./modules/aws_iam_role_policy"
  name      = "Reader-stackgen_c79332"
  policy    = "{\n  \"Version\": \"2012-10-17\",\n  \"Statement\": [\n    {\n      \"Sid\": \"c5d6f2e4663a4cb7aa0702f8f5058a690\",\n      \"Action\": [\n        \"rds:DescribeDBInstances\",\n        \"rds:DescribeDBSnapshots\",\n        \"rds:DescribeDBClusters\",\n        \"rds:DescribeDBSubnetGroups\",\n        \"rds:DescribeDBClusterSnapshots\",\n        \"rds:DescribeDBParameterGroups\",\n        \"rds:DescribeDBParameters\",\n        \"rds:DescribeDBEngineVersions\",\n        \"rds:DescribeEvents\",\n        \"rds:DescribeEventSubscriptions\"\n      ],\n      \"Effect\": \"Allow\",\n      \"Resource\": [\n        \"${module.stackgen_$${module.stackgen_5fd40805-7076-4a15-8d0e-6cdf9d44be90.arn}.arn}\"\n      ]\n    }\n  ]\n}"
  role      = module.stackgen_5eed13ab-1aa7-466a-b68e-228ec38ad06c.name
  role_type = "Reader"
}

module "stackgen_1680b4dd-8a42-4d84-8003-dbd532ed6b85" {
  source                       = "./modules/aws_elasticache"
  access_string                = "on ~* +@all"
  az_mode                      = "single-az"
  cloudwatch_retention_in_days = 30
  cluster_id                   = "notification-cache"
  enable_redis_log_delivery    = false
  engine                       = "redis"
  family                       = "redis7"
  log_format                   = "json"
  log_type                     = "engine-log"
  node_type                    = "cache.t3.small"
  num_cache_nodes              = 1
  password                     = "NotifCacheP@ss!"
  port                         = 6379
  security_group_ids           = null
  subnet_ids                   = null
  tags = {
    owner   = "retroboard"
    service = "notification"
  }
  use_vpc   = false
  user_id   = "notification-user"
  user_name = "notification"
}

module "stackgen_507a1461-80e3-4e4f-946c-215d32505e41" {
  source                       = "./modules/aws_s3"
  block_public_access          = true
  bucket_name                  = "notification-service-28630a42"
  bucket_policy                = ""
  enable_versioning            = true
  enable_website_configuration = false
  sse_algorithm                = "aws:kms"
  tags = {
    owner   = "retroboard"
    service = "notification"
  }
  website_error_document = "404.html"
  website_index_document = "index.html"
}

module "stackgen_5eed13ab-1aa7-466a-b68e-228ec38ad06c" {
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

module "stackgen_5fd40805-7076-4a15-8d0e-6cdf9d44be90" {
  source                           = "./modules/aws_rds"
  cluster_identifier               = "notification-service-db"
  rds_auto_pause                   = true
  rds_availability_zones           = ["us-east-1a", "us-east-1b"]
  rds_backup_retention_period      = 7
  rds_database_name                = "notificationdb"
  rds_db_subnet_group_name         = "default"
  rds_engine                       = "postgres"
  rds_engine_mode                  = "provisioned"
  rds_engine_version               = "16.4"
  rds_master_password              = var.rds_master_password_c5d6f2e4-663a-4cb7-aa07-02f8f5058a69
  rds_master_username              = "notif_admin"
  rds_max_capacity                 = 2
  rds_min_capacity                 = 1
  rds_preferred_backup_window      = "07:00-09:00"
  rds_preferred_maintenance_window = "sun:05:00-sun:06:00"
  rds_storage_encrypted            = true
  region                           = var.region
  security_groups                  = null
  tags = {
    owner   = "retroboard"
    service = "notification"
  }
  use_custom_kms_key_for_encryption = false
}

module "stackgen_8c8634c7-0670-41fb-b6fa-89496d352e2a" {
  source    = "./modules/aws_iam_role_policy"
  name      = "Reader-stackgen_390ec1"
  policy    = "{\n  \"Version\": \"2012-10-17\",\n  \"Statement\": [\n    {\n      \"Sid\": \"4ed341009c774540ac4f8ff1194b396d0\",\n      \"Action\": [\n        \"elasticache:Describe*\"\n      ],\n      \"Effect\": \"Allow\",\n      \"Resource\": [\n        \"${module.stackgen_$${module.stackgen_1680b4dd-8a42-4d84-8003-dbd532ed6b85.arn}.arn}\"\n      ]\n    }\n  ]\n}"
  role      = module.stackgen_5eed13ab-1aa7-466a-b68e-228ec38ad06c.name
  role_type = "Reader"
}

module "stackgen_e85b92bd-20d7-4906-a232-4b097d41f790" {
  source    = "./modules/aws_iam_role_policy"
  name      = "Reader-stackgen_e8dba1"
  policy    = "{\n  \"Version\": \"2012-10-17\",\n  \"Statement\": [\n    {\n      \"Sid\": \"00d08c90ab3246acab693a1a453059720\",\n      \"Action\": [\n        \"s3:Get*\",\n        \"s3:List*\"\n      ],\n      \"Effect\": \"Allow\",\n      \"Resource\": [\n        \"${module.stackgen_$${module.stackgen_507a1461-80e3-4e4f-946c-215d32505e41.arn}.arn}\",\n        \"${module.stackgen_00d08c90-ab32-46ac-ab69-3a1a45305972.arn}/*\"\n      ]\n    }\n  ]\n}"
  role      = module.stackgen_5eed13ab-1aa7-466a-b68e-228ec38ad06c.name
  role_type = "Reader"
}

