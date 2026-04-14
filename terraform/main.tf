module "stackgen_06bd552c-442f-4a99-86fa-e5787505ead1" {
  source                                = "git::https://github.com/cesar-terraform-modules/tf-monorepo.git//modules/fargate-ecs-bluegreen?ref=retroboard"
  assign_public_ip                      = false
  cluster_name                          = local.prefix
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
  container_definitions                 = [{ name = "${local.prefix}-app", image = "${var.ecr_app_url}:latest", essential = true, portMappings = [{ containerPort = 3000, hostPort = 3000, protocol = "tcp" }], logConfiguration = { logDriver = "awslogs", options = { "awslogs-group" = "/ecs/${local.prefix}-app", "awslogs-region" = "us-east-1", "awslogs-stream-prefix" = "ecs" } } }]
  create_cluster                        = true
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
  health_check_grace_period_seconds     = 60
  load_balancers                        = [{ target_group_arn = local.alb.target_group_arns["${local.prefix}-app"], container_name = "${local.prefix}-app", container_port = 3000 }]
  log_group_name                        = null
  log_retention_in_days                 = 30
  platform_version                      = "LATEST"
  security_group_ids                    = [local.alb.ecs_security_group_id]
  service_name                          = "${local.prefix}-app"
  service_registries                    = []
  subnet_ids                            = var.private_subnet_ids
  tags                                  = {}
  task_cpu                              = "256"
  task_family                           = "${local.prefix}-app"
  task_memory                           = "512"
  task_role_additional_policies         = []
  task_role_arn                         = null
  volumes                               = []
}

module "stackgen_121b0cf0-2050-4bb5-9578-c8dfd5d52f3d" {
  source                     = "git::https://github.com/cesar-terraform-modules/tf-monorepo.git//modules/ses-email?ref=retroboard"
  from_email                 = var.ses_from_email
  html_body                  = "<html>\n  <body>\n    <h2>Retroboard Summary for {{board_name}}</h2>\n    <p>View the full summary at <a href=\"{{summary_url}}\">{{summary_url}}</a></p>\n    <p><strong>Completed items:</strong> {{completed_items}}</p>\n    <p><strong>Pending items:</strong> {{pending_items}}</p>\n  </body>\n</html>\n"
  region                     = "us-east-1"
  skip_identity_verification = false
  subject                    = "Retroboard summary for {{board_name}}"
  tags                       = {}
  template_name              = "retroboard-summary"
  text_body                  = "Retroboard summary for {{board_name}}. View details at {{summary_url}}. Completed: {{completed_items}}. Pending: {{pending_items}}."
}

module "stackgen_40ff659d-c39a-4886-a9f6-995bd45fca9a" {
  source                                = "git::https://github.com/cesar-terraform-modules/tf-monorepo.git//modules/fargate-ecs-bluegreen?ref=retroboard"
  assign_public_ip                      = false
  cluster_name                          = "${local.ecs_cluster_name}"
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
  codedeploy_test_listener_arns         = []
  container_definitions = [{
    environment = [{
      name  = "PORT"
      value = "8000"
      }, {
      name  = "SLACK_WEBHOOK_URL"
      value = "https://hooks.slack.com/services/placeholder"
    }]
    essential = true
    image     = "${var.ecr_notification_url}:latest"
    logConfiguration = {
      logDriver = "awslogs"
      options = {
        awslogs-group         = "/ecs/${local.prefix}-notification"
        awslogs-region        = "us-east-1"
        awslogs-stream-prefix = "ecs"
      }
    }
    name = "${local.prefix}-notification"
    portMappings = [{
      containerPort = 8000
      hostPort      = 8000
      protocol      = "tcp"
    }]
  }]
  create_cluster                     = false
  create_codedeploy_role             = true
  create_execution_role              = true
  create_log_group                   = true
  create_task_role                   = true
  deployment_maximum_percent         = 200
  deployment_minimum_healthy_percent = 100
  desired_count                      = 1
  enable_blue_green_deployment       = false
  enable_container_insights          = true
  enable_execute_command             = false
  execution_role_arn                 = "${module.stackgen_cfe1a524-aebc-4f57-8f0a-b50cf509d3a0.execution_role_arn}"
  health_check_grace_period_seconds  = null
  load_balancers                     = []
  log_group_name                     = null
  log_retention_in_days              = 30
  platform_version                   = "LATEST"
  security_group_ids                 = ["${local.alb.ecs_security_group_id}"]
  service_name                       = "${local.prefix}-notification"
  service_registries = [{
    registry_arn = "${local.sd.service_arns["notification"]}"
  }]
  subnet_ids                    = "${var.private_subnet_ids}"
  tags                          = {}
  task_cpu                      = "256"
  task_family                   = "${local.prefix}-notification"
  task_memory                   = "512"
  task_role_additional_policies = []
  task_role_arn                 = null
  volumes                       = []
}

module "stackgen_5e8e283a-36e8-437c-8c37-35ee89490bbc" {
  source         = "git::https://github.com/cesar-terraform-modules/tf-monorepo.git//modules/service-discovery?ref=retroboard"
  namespace_name = "${local.prefix}.local"
  services       = [{ name = "email-summary" }, { name = "notification" }]
  tags           = {}
  vpc_id         = var.vpc_id
}

module "stackgen_92de71a0-ae3e-4969-afae-5ac4db9402d4" {
  source                           = "git::https://github.com/cesar-terraform-modules/tf-monorepo.git//modules/alb?ref=retroboard"
  allowed_cidrs                    = ["0.0.0.0/0"]
  certificate_arn                  = null
  create_ecs_security_group        = true
  ecs_sg_name_prefix               = "${local.prefix}-ecs"
  enable_https                     = false
  health_check_healthy_threshold   = 3
  health_check_interval            = 30
  health_check_unhealthy_threshold = 3
  http_default_action              = "forward"
  internal                         = false
  listener_rules                   = [{ priority = 100, target_group_name = "${local.prefix}-api", path_patterns = ["/boards*", "/email-summary*", "/docs*"] }]
  name                             = "${local.prefix}-alb"
  subnet_ids                       = var.public_subnet_ids
  tags                             = {}
  target_groups                    = [{ name = "${local.prefix}-app", port = 3000, protocol = "HTTP", health_check_path = "/", health_check_matcher = "200" }, { name = "${local.prefix}-api", port = 8000, protocol = "HTTP", health_check_path = "/docs", health_check_matcher = "200" }]
  vpc_id                           = var.vpc_id
}

module "stackgen_9853203f-e083-4a80-87d3-6575d5d2a3e5" {
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
  table_name                     = "${local.prefix}-boards"
  tags                           = {}
  ttl_attribute_name             = ""
  ttl_enabled                    = false
  write_capacity                 = 5
}

module "stackgen_9adbcf4b-9a58-461b-8fc8-95866dcd9afe" {
  source                                = "git::https://github.com/cesar-terraform-modules/tf-monorepo.git//modules/fargate-ecs-bluegreen?ref=retroboard"
  assign_public_ip                      = false
  cluster_name                          = local.ecs_cluster_name
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
  container_definitions                 = [{ name = "${local.prefix}-api", image = "${var.ecr_api_url}:latest", essential = true, portMappings = [{ containerPort = 8000, hostPort = 8000, protocol = "tcp" }], environment = [{ name = "PORT", value = "8000" }, { name = "AWS_REGION", value = "us-east-1" }, { name = "DYNAMODB_TABLE_NAME", value = "${local.prefix}-boards" }, { name = "EMAILS_SQS_QUEUE", value = "${local.prefix}-emails" }, { name = "SLACK_ALERTS_SNS_TOPIC", value = "${local.prefix}-alerts" }, { name = "CORS_ALLOWED_ORIGINS", value = "*" }], logConfiguration = { logDriver = "awslogs", options = { "awslogs-group" = "/ecs/${local.prefix}-api", "awslogs-region" = "us-east-1", "awslogs-stream-prefix" = "ecs" } } }]
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
  execution_role_arn                    = local.iam_api.execution_role_arn
  health_check_grace_period_seconds     = 60
  load_balancers                        = [{ target_group_arn = local.alb.target_group_arns["${local.prefix}-api"], container_name = "${local.prefix}-api", container_port = 8000 }]
  log_group_name                        = null
  log_retention_in_days                 = 30
  platform_version                      = "LATEST"
  security_group_ids                    = [local.alb.ecs_security_group_id]
  service_name                          = "${local.prefix}-api"
  service_registries                    = []
  subnet_ids                            = var.private_subnet_ids
  tags                                  = {}
  task_cpu                              = "256"
  task_family                           = "${local.prefix}-api"
  task_memory                           = "512"
  task_role_additional_policies         = []
  task_role_arn                         = module.stackgen_cfe1a524-aebc-4f57-8f0a-b50cf509d3a0.task_role_arn
  volumes                               = []
}

module "stackgen_a66ffb34-898c-4d02-92cb-5ea38482723e" {
  source                    = "git::https://github.com/cesar-terraform-modules/tf-monorepo.git//modules/ecs-task-iam?ref=retroboard"
  assumable_role_arns       = []
  cloudwatch_log_group_arns = ["arn:aws:logs:us-east-1:${var.aws_account_id}:log-group:/ecs/${local.prefix}-email-summary*"]
  dynamodb_table_arns       = []
  ecr_repository_arns       = ["arn:aws:ecr:us-east-1:${var.aws_account_id}:repository/retroboard/*"]
  enable_cloudwatch_logs    = true
  enable_dynamodb           = false
  enable_ecr_pull           = true
  enable_ses_send_email     = true
  enable_sns_publish        = false
  enable_sqs_send_receive   = true
  enable_sts_assume_role    = false
  name                      = "${local.prefix}-email-summary"
  ses_identity_arns         = [local.ses.identity_arn]
  sns_topic_arns            = []
  sqs_queue_arns            = [local.sqs.queue_arn]
  tags                      = {}
}

module "stackgen_b661ecf9-4189-4639-a2d5-4d2da03fa08c" {
  source                      = "git::https://github.com/cesar-terraform-modules/tf-monorepo.git//modules/sns-topic?ref=retroboard"
  content_based_deduplication = true
  delivery_policy             = null
  display_name                = null
  fifo_topic                  = false
  kms_master_key_id           = null
  subscriptions               = []
  tags                        = {}
  topic_name                  = "${local.prefix}-alerts"
  topic_policy                = null
}

module "stackgen_cfe1a524-aebc-4f57-8f0a-b50cf509d3a0" {
  source                    = "git::https://github.com/cesar-terraform-modules/tf-monorepo.git//modules/ecs-task-iam?ref=retroboard"
  assumable_role_arns       = []
  cloudwatch_log_group_arns = ["arn:aws:logs:us-east-1:${var.aws_account_id}:log-group:/ecs/${local.prefix}-api*"]
  dynamodb_table_arns       = [local.dynamodb.table_arn]
  ecr_repository_arns       = ["arn:aws:ecr:us-east-1:${var.aws_account_id}:repository/retroboard/*"]
  enable_cloudwatch_logs    = true
  enable_dynamodb           = true
  enable_ecr_pull           = true
  enable_ses_send_email     = false
  enable_sns_publish        = true
  enable_sqs_send_receive   = true
  enable_sts_assume_role    = false
  name                      = "${local.prefix}-api"
  ses_identity_arns         = []
  sns_topic_arns            = [local.sns.topic_arn]
  sqs_queue_arns            = [local.sqs.queue_arn]
  tags                      = {}
}

module "stackgen_d53b58a7-fe4d-4629-aab3-cc5e36c7e8ff" {
  source                                = "git::https://github.com/cesar-terraform-modules/tf-monorepo.git//modules/fargate-ecs-bluegreen?ref=retroboard"
  assign_public_ip                      = false
  cluster_name                          = local.ecs_cluster_name
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
  container_definitions                 = [{ name = "${local.prefix}-email-summary", image = "${var.ecr_email_summary_url}:latest", essential = true, portMappings = [{ containerPort = 8000, hostPort = 8000, protocol = "tcp" }], environment = [{ name = "PORT", value = "8000" }, { name = "AWS_REGION", value = "us-east-1" }, { name = "SES_SENDER_EMAIL_ADDRESS", value = var.ses_from_email }, { name = "TEMPLATE_NAME", value = "retroboard-summary" }], logConfiguration = { logDriver = "awslogs", options = { "awslogs-group" = "/ecs/${local.prefix}-email-summary", "awslogs-region" = "us-east-1", "awslogs-stream-prefix" = "ecs" } } }]
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
  execution_role_arn                    = local.iam_email_summary.execution_role_arn
  health_check_grace_period_seconds     = null
  load_balancers                        = []
  log_group_name                        = null
  log_retention_in_days                 = 30
  platform_version                      = "LATEST"
  security_group_ids                    = [local.alb.ecs_security_group_id]
  service_name                          = "${local.prefix}-email-summary"
  service_registries                    = [{ registry_arn = local.sd.service_arns["email-summary"] }]
  subnet_ids                            = var.private_subnet_ids
  tags                                  = {}
  task_cpu                              = "256"
  task_family                           = "${local.prefix}-email-summary"
  task_memory                           = "512"
  task_role_additional_policies         = []
  task_role_arn                         = module.stackgen_a66ffb34-898c-4d02-92cb-5ea38482723e.task_role_arn
  volumes                               = []
}

module "stackgen_ed5d6bb0-86b1-40a4-bcc6-aca8f07f0c18" {
  source                        = "git::https://github.com/cesar-terraform-modules/tf-monorepo.git//modules/sqs-queue?ref=retroboard"
  content_based_deduplication   = true
  dlq_message_retention_seconds = 1209600
  dlq_name                      = "${local.prefix}-emails-dlq"
  enable_dlq                    = true
  fifo_queue                    = false
  kms_key_id                    = null
  max_message_size              = 262144
  message_retention_seconds     = 345600
  queue_name                    = "${local.prefix}-emails"
  queue_policy_statements       = []
  redrive_max_receive_count     = 5
  tags                          = {}
  visibility_timeout_seconds    = 30
}

