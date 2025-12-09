module "stackgen_571b3d45-ff28-444f-af1d-5c30fdbc08ca" {
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

module "stackgen_595dfc8a-f2ec-4e8f-8ad0-d23b64a73efc" {
  source    = "./modules/aws_iam_role_policy"
  name      = "Reader-stackgen_46b080"
  policy    = "{\n  \"Version\": \"2012-10-17\",\n  \"Statement\": [\n    {\n      \"Sid\": \"96da2fb161a4466c98cc3a6984650eaa0\",\n      \"Action\": [\n        \"s3:Get*\",\n        \"s3:List*\"\n      ],\n      \"Effect\": \"Allow\",\n      \"Resource\": [\n        \"${module.stackgen_96da2fb1-61a4-466c-98cc-3a6984650eaa.arn}\",\n        \"${module.stackgen_96da2fb1-61a4-466c-98cc-3a6984650eaa.arn}/*\"\n      ]\n    }\n  ]\n}"
  role      = module.stackgen_cec558cb-7aca-44d3-8eba-820df0d31dc4.name
  role_type = "Reader"
}

module "stackgen_64e39f06-9a7d-4a8a-a419-7b3817247838" {
  source    = "./modules/aws_iam_role_policy"
  name      = "Reader-stackgen_8b7ab2"
  policy    = "{\n  \"Version\": \"2012-10-17\",\n  \"Statement\": [\n    {\n      \"Sid\": \"d1eb80b0b327435db0bbcf02a6db521b0\",\n      \"Action\": [\n        \"sns:ListTopics\",\n        \"sns:ListSubscriptionsByTopic\",\n        \"sns:GetTopicAttributes\",\n        \"sns:ListSubscriptions\",\n        \"sns:GetSubscriptionAttributes\"\n      ],\n      \"Effect\": \"Allow\",\n      \"Resource\": [\n        \"${module.stackgen_d1eb80b0-b327-435d-b0bb-cf02a6db521b.arn}\"\n      ]\n    }\n  ]\n}"
  role      = module.stackgen_cec558cb-7aca-44d3-8eba-820df0d31dc4.name
  role_type = "Reader"
}

module "stackgen_96da2fb1-61a4-466c-98cc-3a6984650eaa" {
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

module "stackgen_cec558cb-7aca-44d3-8eba-820df0d31dc4" {
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

module "stackgen_d1eb80b0-b327-435d-b0bb-cf02a6db521b" {
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

module "stackgen_de3734d5-b3a2-465e-8e83-a89946412130" {
  source                    = "./modules/aws_ecs"
  cpu_architecture          = "X86_64"
  create_ingress_alb        = true
  ecs_cluster_name          = module.stackgen_571b3d45-ff28-444f-af1d-5c30fdbc08ca.name
  ecs_service_desired_count = 1
  ecs_service_name          = "retroboard-notification-service"
  ecs_task_container_cpu    = 256
  ecs_task_container_memory = 512
  ecs_task_container_name   = "notification-service"
  ecs_task_container_port   = 8000
  ecs_task_image_url        = "180217099948.dkr.ecr.us-east-2.amazonaws.com/retroboard-notification-service:latest"
  environment_variables = {
    SLACK_WEBHOOK_URL = "https://hooks.slack.com/services/TEST/WEBHOOK/URL"
  }
  health_check_path  = "/"
  internal_alb       = false
  network_mode       = "awsvpc"
  operating_system   = "LINUX"
  private_subnet_ids = []
  protocol           = "HTTP"
  public_subnet_ids  = ["subnet-0785dd490f8091bc6", "subnet-04bb33ccc84d34fbd", "subnet-0332d2c90f23b6275"]
  region             = var.region
  tags = {
    app     = "retroboard"
    service = "notification"
  }
  task_role_arn = module.stackgen_cec558cb-7aca-44d3-8eba-820df0d31dc4.arn
}

