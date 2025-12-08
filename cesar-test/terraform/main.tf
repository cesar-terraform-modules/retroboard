module "stackgen_14347820-7bc8-4212-8c2e-551e87daec8f" {
  source    = "./modules/aws_iam_role_policy"
  name      = "Reader-stackgen_390ec1"
  policy    = "{\n  \"Version\": \"2012-10-17\",\n  \"Statement\": [\n    {\n      \"Sid\": \"4ed341009c774540ac4f8ff1194b396d0\",\n      \"Action\": [\n        \"elasticache:Describe*\"\n      ],\n      \"Effect\": \"Allow\",\n      \"Resource\": [\n        \"${module.stackgen_$${module.stackgen_3524dea3-9151-468b-b013-1e607edea4fb.arn}.arn}\"\n      ]\n    }\n  ]\n}"
  role      = module.stackgen_918a9284-8120-46b8-b317-81e62adbbf04.name
  role_type = "Reader"
}

module "stackgen_3524dea3-9151-468b-b013-1e607edea4fb" {
  source                       = "./modules/aws_elasticache"
  access_string                = "on ~* +@all"
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
  password                     = null
  port                         = 6379
  security_group_ids           = []
  subnet_ids                   = []
  tags                         = {}
  use_vpc                      = false
  user_id                      = "slack-alerts-cache-userid"
  user_name                    = "slack-alerts-cache-user"
}

module "stackgen_3dae6a04-f92a-422d-80e2-1f45937d4f97" {
  source    = "./modules/aws_iam_role_policy"
  name      = "Reader-stackgen_e8dba1"
  policy    = "{\n  \"Version\": \"2012-10-17\",\n  \"Statement\": [\n    {\n      \"Sid\": \"00d08c90ab3246acab693a1a453059720\",\n      \"Action\": [\n        \"s3:Get*\",\n        \"s3:List*\"\n      ],\n      \"Effect\": \"Allow\",\n      \"Resource\": [\n        \"${module.stackgen_$${module.stackgen_e7d11ef5-d2c5-4e61-95e9-f276f70cf934.arn}.arn}\",\n        \"${module.stackgen_00d08c90-ab32-46ac-ab69-3a1a45305972.arn}/*\"\n      ]\n    }\n  ]\n}"
  role      = module.stackgen_918a9284-8120-46b8-b317-81e62adbbf04.name
  role_type = "Reader"
}

module "stackgen_90477039-aec6-4080-a8e4-7fd375196df8" {
  source    = "./modules/aws_iam_role_policy"
  name      = "Reader-stackgen_c79332"
  policy    = "{\n  \"Version\": \"2012-10-17\",\n  \"Statement\": [\n    {\n      \"Sid\": \"c5d6f2e4663a4cb7aa0702f8f5058a690\",\n      \"Action\": [\n        \"rds:DescribeDBInstances\",\n        \"rds:DescribeDBSnapshots\",\n        \"rds:DescribeDBClusters\",\n        \"rds:DescribeDBSubnetGroups\",\n        \"rds:DescribeDBClusterSnapshots\",\n        \"rds:DescribeDBParameterGroups\",\n        \"rds:DescribeDBParameters\",\n        \"rds:DescribeDBEngineVersions\",\n        \"rds:DescribeEvents\",\n        \"rds:DescribeEventSubscriptions\"\n      ],\n      \"Effect\": \"Allow\",\n      \"Resource\": [\n        \"${module.stackgen_$${module.stackgen_b6545ab0-df89-49fe-9f96-64daa1a6755b.arn}.arn}\"\n      ]\n    }\n  ]\n}"
  role      = module.stackgen_918a9284-8120-46b8-b317-81e62adbbf04.name
  role_type = "Reader"
}

module "stackgen_918a9284-8120-46b8-b317-81e62adbbf04" {
  source                = "./modules/aws_iam_role"
  assume_role_policy    = "{\n  \"Version\": \"2012-10-17\",\n  \"Statement\": {\n    \"Action\": \"sts:AssumeRole\",\n    \"Effect\": \"Allow\",\n    \"Principal\": {\"Service\": \"eks.amazonaws.com\"}\n  }\n}"
  description           = null
  force_detach_policies = true
  inline_policy         = []
  max_session_duration  = null
  name                  = "stackgen-91d5be-role"
  path                  = null
  permissions_boundary  = null
  tags                  = null
}

module "stackgen_b6545ab0-df89-49fe-9f96-64daa1a6755b" {
  source                            = "./modules/aws_rds"
  cluster_identifier                = "slack-alerts-db"
  rds_auto_pause                    = true
  rds_availability_zones            = ["us-east-1a", "us-east-1b"]
  rds_backup_retention_period       = 9
  rds_database_name                 = "retroboard_alerts"
  rds_db_subnet_group_name          = "default"
  rds_engine                        = "postgres"
  rds_engine_mode                   = "provisioned"
  rds_engine_version                = "16.4"
  rds_master_password               = var.rds_master_password_c5d6f2e4-663a-4cb7-aa07-02f8f5058a69
  rds_master_username               = "alerts_admin"
  rds_max_capacity                  = 2
  rds_min_capacity                  = 1
  rds_preferred_backup_window       = "07:00-09:00"
  rds_preferred_maintenance_window  = "sun:05:00-sun:06:00"
  rds_storage_encrypted             = true
  region                            = var.region
  security_groups                   = []
  tags                              = {}
  use_custom_kms_key_for_encryption = false
}

module "stackgen_e7d11ef5-d2c5-4e61-95e9-f276f70cf934" {
  source                       = "./modules/aws_s3"
  block_public_access          = true
  bucket_name                  = "retroboard-slack-alerts-bucket-001"
  bucket_policy                = ""
  enable_versioning            = true
  enable_website_configuration = false
  sse_algorithm                = "aws:kms"
  tags                         = {}
  website_error_document       = "404.html"
  website_index_document       = "index.html"
}

