module "stackgen_10d934d4-5ad6-4653-a85e-c6c934eb8f97" {
  source                      = "git::https://github.com/cesar-terraform-modules/tf-monorepo.git//modules/sns-topic?ref=retroboard"
  content_based_deduplication = true
  delivery_policy             = null
  display_name                = null
  fifo_topic                  = false
  kms_master_key_id           = null
  subscriptions               = []
  tags                        = {}
  topic_name                  = "${var.project}-${var.environment}-alerts"
  topic_policy                = null
}

module "stackgen_12d49d31-f258-452f-959f-e7db67b06651" {
  source         = "git::https://github.com/cesar-terraform-modules/tf-monorepo.git//modules/service-discovery?ref=retroboard"
  namespace_name = "${var.project}-${var.environment}.local"
  services = [{
    name = "email-summary"
    }, {
    name = "notification"
  }]
  tags   = {}
  vpc_id = local.infra.vpc_id
}

module "stackgen_1c652d94-e49a-4571-a084-ed3f17f3c6c3" {
  source                        = "git::https://github.com/cesar-terraform-modules/tf-monorepo.git//modules/sqs-queue?ref=retroboard"
  content_based_deduplication   = true
  dlq_message_retention_seconds = 1209600
  dlq_name                      = null
  enable_dlq                    = true
  fifo_queue                    = false
  kms_key_id                    = null
  max_message_size              = 262144
  message_retention_seconds     = 345600
  queue_name                    = "${var.project}-${var.environment}-emails"
  queue_policy_statements       = []
  redrive_max_receive_count     = 5
  tags                          = {}
  visibility_timeout_seconds    = 30
}

module "stackgen_575408b8-ea0e-43e4-b6f3-4d37253e199e" {
  source                                = "git::https://github.com/cesar-terraform-modules/tf-monorepo.git//modules/fargate-ecs-bluegreen?ref=retroboard"
  assign_public_ip                      = false
  cluster_name                          = "${var.project}-${var.environment}"
  codedeploy_auto_rollback_enabled      = true
  codedeploy_auto_rollback_events       = ["DEPLOYMENT_FAILURE", "DEPLOYMENT_STOP_ON_ALARM"]
  codedeploy_blue_target_group_name     = null
  codedeploy_deployment_config          = "CodeDeployDefault.ECSAllAtOnce"
  codedeploy_deployment_ready_action    = "CONTINUE_DEPLOYMENT"
  codedeploy_deployment_ready_wait_time = 0
  codedeploy_green_target_group_name    = null
  codedeploy_listener_arns              = []
  codedeploy_role_arn                   = null
  codedeploy_terminate_blue_action      = "TERMINATE"
  codedeploy_terminate_blue_wait_time   = 5
  codedeploy_test_listener_arns         = null
  container_definitions                 = local.email_summary_container_defs
  create_cluster                        = false
  create_codedeploy_role                = true
  create_execution_role                 = false
  create_log_group                      = true
  create_task_role                      = false
  deployment_maximum_percent            = 200
  deployment_minimum_healthy_percent    = 100
  desired_count                         = 1
  enable_blue_green_deployment          = false
  enable_container_insights             = true
  enable_execute_command                = false
  execution_role_arn                    = local.email_iam.execution_role_arn
  health_check_grace_period_seconds     = null
  load_balancers                        = []
  log_group_name                        = "/ecs/${var.project}-${var.environment}-email-summary"
  log_retention_in_days                 = 30
  platform_version                      = "1.4.0"
  security_group_ids                    = [local.alb.ecs_security_group_id]
  service_name                          = "${var.project}-${var.environment}-email-summary"
  service_registries                    = local.email_summary_service_registries
  subnet_ids                            = local.infra.private_subnet_ids
  tags                                  = {}
  task_cpu                              = "256"
  task_family                           = "${var.project}-${var.environment}-email-summary"
  task_memory                           = "512"
  task_role_additional_policies         = []
  task_role_arn                         = local.email_iam.task_role_arn
  volumes                               = []
}

module "stackgen_6e047b6f-714e-4011-b050-e33d5b0a026c" {
  source                     = "git::https://github.com/cesar-terraform-modules/tf-monorepo.git//modules/ses-email?ref=retroboard"
  from_email                 = var.ses_sender_email
  html_body                  = "<html>\n  <body>\n    <h2>Retroboard Summary for {{board_name}}</h2>\n    <p>View the full summary at <a href=\"{{summary_url}}\">{{summary_url}}</a></p>\n    <p><strong>Completed items:</strong> {{completed_items}}</p>\n    <p><strong>Pending items:</strong> {{pending_items}}</p>\n  </body>\n</html>\n"
  region                     = "us-east-1"
  skip_identity_verification = false
  subject                    = "Retroboard summary for {{board_name}}"
  tags                       = {}
  template_name              = "retroboard-summary"
  text_body                  = "Retroboard summary for {{board_name}}. View details at {{summary_url}}. Completed: {{completed_items}}. Pending: {{pending_items}}."
}

module "stackgen_6e5ee8be-2793-433b-bc54-fc93f7698f70" {
  source                    = "git::https://github.com/cesar-terraform-modules/tf-monorepo.git//modules/ecs-task-iam?ref=retroboard"
  assumable_role_arns       = []
  cloudwatch_log_group_arns = [local.log_group_arn_pattern]
  dynamodb_table_arns       = [local.boards.table_arn]
  ecr_repository_arns       = values(local.infra.ecr_repository_arns)
  enable_cloudwatch_logs    = true
  enable_dynamodb           = true
  enable_ecr_pull           = true
  enable_ses_send_email     = false
  enable_sns_publish        = true
  enable_sqs_send_receive   = true
  enable_sts_assume_role    = false
  name                      = "${var.project}-${var.environment}-api"
  ses_identity_arns         = []
  sns_topic_arns            = [local.alerts.topic_arn]
  sqs_queue_arns            = [local.email_queue.queue_arn]
  tags                      = {}
}

module "stackgen_73c31d0f-f834-446c-baa1-4ef09d9feb39" {
  source                                = "git::https://github.com/cesar-terraform-modules/tf-monorepo.git//modules/fargate-ecs-bluegreen?ref=retroboard"
  assign_public_ip                      = false
  cluster_name                          = "${var.project}-${var.environment}"
  codedeploy_auto_rollback_enabled      = true
  codedeploy_auto_rollback_events       = ["DEPLOYMENT_FAILURE", "DEPLOYMENT_STOP_ON_ALARM"]
  codedeploy_blue_target_group_name     = null
  codedeploy_deployment_config          = "CodeDeployDefault.ECSAllAtOnce"
  codedeploy_deployment_ready_action    = "CONTINUE_DEPLOYMENT"
  codedeploy_deployment_ready_wait_time = 0
  codedeploy_green_target_group_name    = null
  codedeploy_listener_arns              = []
  codedeploy_role_arn                   = null
  codedeploy_terminate_blue_action      = "TERMINATE"
  codedeploy_terminate_blue_wait_time   = 5
  codedeploy_test_listener_arns         = null
  container_definitions                 = local.notification_container_defs
  create_cluster                        = false
  create_codedeploy_role                = true
  create_execution_role                 = true
  create_log_group                      = true
  create_task_role                      = true
  deployment_maximum_percent            = 200
  deployment_minimum_healthy_percent    = 100
  desired_count                         = 1
  enable_blue_green_deployment          = false
  enable_container_insights             = true
  enable_execute_command                = false
  execution_role_arn                    = null
  health_check_grace_period_seconds     = null
  load_balancers                        = []
  log_group_name                        = "/ecs/${var.project}-${var.environment}-notification"
  log_retention_in_days                 = 30
  platform_version                      = "1.4.0"
  security_group_ids                    = [local.alb.ecs_security_group_id]
  service_name                          = "${var.project}-${var.environment}-notification"
  service_registries                    = local.notification_service_registries
  subnet_ids                            = local.infra.private_subnet_ids
  tags                                  = {}
  task_cpu                              = "256"
  task_family                           = "${var.project}-${var.environment}-notification"
  task_memory                           = "512"
  task_role_additional_policies         = []
  task_role_arn                         = null
  volumes                               = []
}

module "stackgen_9896ab00-c865-451a-aa3e-18bebe04018c" {
  source                                = "git::https://github.com/cesar-terraform-modules/tf-monorepo.git//modules/fargate-ecs-bluegreen?ref=retroboard"
  assign_public_ip                      = false
  cluster_name                          = "${var.project}-${var.environment}"
  codedeploy_auto_rollback_enabled      = true
  codedeploy_auto_rollback_events       = ["DEPLOYMENT_FAILURE", "DEPLOYMENT_STOP_ON_ALARM"]
  codedeploy_blue_target_group_name     = "${var.project}-${var.environment}-app-blue"
  codedeploy_deployment_config          = "CodeDeployDefault.ECSAllAtOnce"
  codedeploy_deployment_ready_action    = "CONTINUE_DEPLOYMENT"
  codedeploy_deployment_ready_wait_time = 0
  codedeploy_green_target_group_name    = "${var.project}-${var.environment}-app-green"
  codedeploy_listener_arns              = [local.alb.listener_arn]
  codedeploy_role_arn                   = null
  codedeploy_terminate_blue_action      = "TERMINATE"
  codedeploy_terminate_blue_wait_time   = 5
  codedeploy_test_listener_arns         = null
  container_definitions                 = local.app_container_defs
  create_cluster                        = false
  create_codedeploy_role                = true
  create_execution_role                 = true
  create_log_group                      = true
  create_task_role                      = true
  deployment_maximum_percent            = 200
  deployment_minimum_healthy_percent    = 100
  desired_count                         = 1
  enable_blue_green_deployment          = true
  enable_container_insights             = true
  enable_execute_command                = false
  execution_role_arn                    = null
  health_check_grace_period_seconds     = 60
  load_balancers                        = local.app_load_balancers
  log_group_name                        = "/ecs/${var.project}-${var.environment}-app"
  log_retention_in_days                 = 30
  platform_version                      = "1.4.0"
  security_group_ids                    = [local.alb.ecs_security_group_id]
  service_name                          = "${var.project}-${var.environment}-app"
  service_registries                    = []
  subnet_ids                            = local.infra.private_subnet_ids
  tags                                  = {}
  task_cpu                              = "256"
  task_family                           = "${var.project}-${var.environment}-app"
  task_memory                           = "512"
  task_role_additional_policies         = []
  task_role_arn                         = null
  volumes                               = []
}

module "stackgen_a0ba9938-4ff7-4d55-9e23-da58bb688bdc" {
  source                                = "git::https://github.com/cesar-terraform-modules/tf-monorepo.git//modules/fargate-ecs-bluegreen?ref=retroboard"
  assign_public_ip                      = false
  cluster_name                          = "${var.project}-${var.environment}"
  codedeploy_auto_rollback_enabled      = true
  codedeploy_auto_rollback_events       = ["DEPLOYMENT_FAILURE", "DEPLOYMENT_STOP_ON_ALARM"]
  codedeploy_blue_target_group_name     = "${var.project}-${var.environment}-api-blue"
  codedeploy_deployment_config          = "CodeDeployDefault.ECSAllAtOnce"
  codedeploy_deployment_ready_action    = "CONTINUE_DEPLOYMENT"
  codedeploy_deployment_ready_wait_time = 0
  codedeploy_green_target_group_name    = "${var.project}-${var.environment}-api-green"
  codedeploy_listener_arns              = [local.alb.listener_arn]
  codedeploy_role_arn                   = null
  codedeploy_terminate_blue_action      = "TERMINATE"
  codedeploy_terminate_blue_wait_time   = 5
  codedeploy_test_listener_arns         = null
  container_definitions                 = local.api_container_defs
  create_cluster                        = true
  create_codedeploy_role                = true
  create_execution_role                 = false
  create_log_group                      = true
  create_task_role                      = false
  deployment_maximum_percent            = 200
  deployment_minimum_healthy_percent    = 100
  desired_count                         = 1
  enable_blue_green_deployment          = true
  enable_container_insights             = true
  enable_execute_command                = false
  execution_role_arn                    = local.api_iam.execution_role_arn
  health_check_grace_period_seconds     = 60
  load_balancers                        = local.api_load_balancers
  log_group_name                        = "/ecs/${var.project}-${var.environment}-api"
  log_retention_in_days                 = 30
  platform_version                      = "1.4.0"
  security_group_ids                    = [local.alb.ecs_security_group_id]
  service_name                          = "${var.project}-${var.environment}-api"
  service_registries                    = []
  subnet_ids                            = local.infra.private_subnet_ids
  tags                                  = {}
  task_cpu                              = "256"
  task_family                           = "${var.project}-${var.environment}-api"
  task_memory                           = "512"
  task_role_additional_policies         = []
  task_role_arn                         = local.api_iam.task_role_arn
  volumes                               = []
}

module "stackgen_b2e96a9a-2919-4896-9b13-83acf8323bf2" {
  source                    = "git::https://github.com/cesar-terraform-modules/tf-monorepo.git//modules/ecs-task-iam?ref=retroboard"
  assumable_role_arns       = []
  cloudwatch_log_group_arns = [local.log_group_arn_pattern]
  dynamodb_table_arns       = []
  ecr_repository_arns       = values(local.infra.ecr_repository_arns)
  enable_cloudwatch_logs    = true
  enable_dynamodb           = false
  enable_ecr_pull           = true
  enable_ses_send_email     = true
  enable_sns_publish        = false
  enable_sqs_send_receive   = true
  enable_sts_assume_role    = false
  name                      = "${var.project}-${var.environment}-email-summary"
  ses_identity_arns         = [local.email.identity_arn]
  sns_topic_arns            = []
  sqs_queue_arns            = [local.email_queue.queue_arn]
  tags                      = {}
}

module "stackgen_c939e17d-3036-4096-9b50-ebc36e69237c" {
  source = "git::https://github.com/cesar-terraform-modules/tf-monorepo.git//modules/dynamodb-global-table?ref=retroboard"
  attributes = [{
    name = "board_id"
    type = "S"
    }, {
    name = "sk"
    type = "S"
  }]
  billing_mode                   = "PAY_PER_REQUEST"
  encryption_enabled             = true
  global_secondary_indexes       = []
  hash_key                       = "board_id"
  kms_key_arn                    = null
  point_in_time_recovery_enabled = true
  range_key                      = "sk"
  read_capacity                  = 5
  replica_kms_key_arns           = null
  replica_regions                = []
  table_name                     = "${var.project}-${var.environment}-boards"
  tags                           = {}
  ttl_attribute_name             = ""
  ttl_enabled                    = false
  write_capacity                 = 5
}

module "stackgen_e68a4061-a05b-4d3a-93a9-203ae5b448f1" {
  source                           = "git::https://github.com/cesar-terraform-modules/tf-monorepo.git//modules/alb?ref=retroboard"
  allowed_cidrs                    = ["0.0.0.0/0"]
  certificate_arn                  = null
  create_ecs_security_group        = true
  ecs_sg_name_prefix               = "${var.project}-${var.environment}-ecs-"
  enable_https                     = false
  health_check_healthy_threshold   = 3
  health_check_interval            = 30
  health_check_unhealthy_threshold = 3
  http_default_action              = "forward"
  internal                         = false
  listener_rules                   = local.alb_listener_rules
  name                             = "${var.project}-${var.environment}-alb"
  subnet_ids                       = local.infra.public_subnet_ids
  tags                             = {}
  target_groups                    = local.alb_target_groups
  vpc_id                           = local.infra.vpc_id
}

