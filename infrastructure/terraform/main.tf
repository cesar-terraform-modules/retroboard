module "stackgen_0dbcc224-0c3d-404b-a33f-3be6c0cc0f52" {
  source    = "./modules/aws_iam_role_policy"
  name      = "Reader-stackgen_8b7ab2"
  policy    = "{\n  \"Version\": \"2012-10-17\",\n  \"Statement\": [\n    {\n      \"Sid\": \"eef4fd45c0ee4a76ae1374b89b20b0470\",\n      \"Action\": [\n        \"sns:ListTopics\",\n        \"sns:ListSubscriptionsByTopic\",\n        \"sns:GetTopicAttributes\",\n        \"sns:ListSubscriptions\",\n        \"sns:GetSubscriptionAttributes\"\n      ],\n      \"Effect\": \"Allow\",\n      \"Resource\": [\n        \"${module.stackgen_eef4fd45-c0ee-4a76-ae13-74b89b20b047.arn}\"\n      ]\n    }\n  ]\n}"
  role      = module.stackgen_d46b18bd-accb-4467-b1d2-05dc816d2eb7.name
  role_type = "Reader"
}

module "stackgen_340b794b-49ec-4862-bd59-601b1a527377" {
  source                       = "./modules/aws_s3"
  block_public_access          = true
  bucket_name                  = "retroboard-notification-artifacts"
  bucket_policy                = ""
  enable_versioning            = true
  enable_website_configuration = false
  sse_algorithm                = "aws:kms"
  tags = {
    app     = "retroboard"
    service = "notification"
  }
  website_error_document = "404.html"
  website_index_document = "index.html"
}

module "stackgen_386b6fa6-385b-4bbd-9f6b-c371e89a9d38" {
  source    = "./modules/aws_iam_role_policy"
  name      = "Reader-stackgen_46b080"
  policy    = "{\n  \"Version\": \"2012-10-17\",\n  \"Statement\": [\n    {\n      \"Sid\": \"340b794b49ec4862bd59601b1a5273770\",\n      \"Action\": [\n        \"s3:Get*\",\n        \"s3:List*\"\n      ],\n      \"Effect\": \"Allow\",\n      \"Resource\": [\n        \"${module.stackgen_340b794b-49ec-4862-bd59-601b1a527377.arn}\",\n        \"${module.stackgen_340b794b-49ec-4862-bd59-601b1a527377.arn}/*\"\n      ]\n    }\n  ]\n}"
  role      = module.stackgen_d46b18bd-accb-4467-b1d2-05dc816d2eb7.name
  role_type = "Reader"
}

module "stackgen_86674cbe-fce3-47e2-84cc-d0615706e8d1" {
  source                    = "./modules/aws_ecs"
  cpu_architecture          = "X86_64"
  create_ingress_alb        = true
  ecs_cluster_name          = module.stackgen_a27fe92c-3834-40e5-ac4d-d25a46ba680f.name
  ecs_service_desired_count = 1
  ecs_service_name          = "retroboard-notification-service"
  ecs_task_container_cpu    = 256
  ecs_task_container_memory = 512
  ecs_task_container_name   = "my-ecs-container"
  ecs_task_container_port   = 80
  ecs_task_image_url        = "public.ecr.aws/docker/library/python:3.11-slim"
  environment_variables = {
    SLACK_WEBHOOK_URL = "https://hooks.slack.com/services/TEST/WEBHOOK/URL"
  }
  health_check_path  = "/"
  internal_alb       = false
  network_mode       = "awsvpc"
  operating_system   = "LINUX"
  private_subnet_ids = []
  protocol           = "HTTP"
  public_subnet_ids  = []
  region             = var.region
  tags               = {}
  task_role_arn      = module.stackgen_d46b18bd-accb-4467-b1d2-05dc816d2eb7.arn
}

module "stackgen_a27fe92c-3834-40e5-ac4d-d25a46ba680f" {
  source                   = "./modules/aws_ecs_cluster"
  configuration            = []
  name                     = "retroboard-notification-cluster"
  service_connect_defaults = []
  setting                  = []
  tags = {
    app     = "retroboard"
    service = "notification"
  }
}

module "stackgen_d46b18bd-accb-4467-b1d2-05dc816d2eb7" {
  source                = "./modules/aws_iam_role"
  assume_role_policy    = "{\n\t\t\"Version\": \"2012-10-17\",\n\t\t\"Statement\":{\n\t\t\t\t\"Action\": \"sts:AssumeRole\",\n\t\t\t\t\"Effect\": \"Allow\",\n\t\t\t\t\"Principal\": {\n\t\t\t\t\t\"Service\": \"ecs-tasks.amazonaws.com\"\n\t\t\t\t}\n\t\t\t}\n\t}"
  description           = null
  force_detach_policies = true
  inline_policy         = []
  max_session_duration  = null
  name                  = "stackgen_0e158c-role"
  path                  = null
  permissions_boundary  = null
  tags                  = null
}

module "stackgen_eef4fd45-c0ee-4a76-ae13-74b89b20b047" {
  source                                   = "./modules/aws_sns"
  application_failure_feedback_role_arn    = null
  application_success_feedback_role_arn    = null
  application_success_feedback_sample_rate = null
  content_based_deduplication              = null
  delivery_policy                          = null
  display_name                             = null
  fifo_topic                               = null
  firehose_failure_feedback_role_arn       = null
  firehose_success_feedback_role_arn       = null
  firehose_success_feedback_sample_rate    = null
  http_failure_feedback_role_arn           = null
  http_success_feedback_role_arn           = null
  http_success_feedback_sample_rate        = null
  lambda_failure_feedback_role_arn         = null
  lambda_success_feedback_role_arn         = null
  lambda_success_feedback_sample_rate      = null
  signature_version                        = null
  sqs_failure_feedback_role_arn            = null
  sqs_success_feedback_role_arn            = null
  sqs_success_feedback_sample_rate         = null
  tags = {
    app     = "retroboard"
    service = "notification"
  }
  topic_name                        = "retroboard-alerts"
  topic_policy                      = ""
  tracing_config                    = null
  use_custom_kms_key_for_encryption = true
}

