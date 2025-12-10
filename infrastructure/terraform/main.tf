module "stackgen_3f8a038f-fc57-4826-ae88-5f396658d09a" {
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
  tags                                     = null
  topic_name                               = "notification-events"
  topic_policy                             = ""
  tracing_config                           = null
  use_custom_kms_key_for_encryption        = true
}

module "stackgen_60c1d459-3b95-415e-92e5-a666c1ea8e2c" {
  source    = "./modules/aws_iam_role_policy"
  name      = "Reader-stackgen_8b7ab2"
  policy    = "{\n  \"Version\": \"2012-10-17\",\n  \"Statement\": [\n    {\n      \"Sid\": \"3f8a038ffc574826ae885f396658d09a0\",\n      \"Action\": [\n        \"sns:ListTopics\",\n        \"sns:ListSubscriptionsByTopic\",\n        \"sns:GetTopicAttributes\",\n        \"sns:ListSubscriptions\",\n        \"sns:GetSubscriptionAttributes\"\n      ],\n      \"Effect\": \"Allow\",\n      \"Resource\": [\n        \"${module.stackgen_3f8a038f-fc57-4826-ae88-5f396658d09a.arn}\"\n      ]\n    }\n  ]\n}"
  role      = module.stackgen_b59373c6-8053-47cb-bee1-68d4b56e6854.name
  role_type = "Reader"
}

module "stackgen_6b048bde-bf9a-4dae-bd07-2411e950c979" {
  source    = "./modules/aws_iam_role_policy"
  name      = "Reader-stackgen_46b080"
  policy    = "{\n  \"Version\": \"2012-10-17\",\n  \"Statement\": [\n    {\n      \"Sid\": \"6d0a676636f34abc8de404776807040e0\",\n      \"Action\": [\n        \"s3:Get*\",\n        \"s3:List*\"\n      ],\n      \"Effect\": \"Allow\",\n      \"Resource\": [\n        \"${module.stackgen_6d0a6766-36f3-4abc-8de4-04776807040e.arn}\",\n        \"${module.stackgen_6d0a6766-36f3-4abc-8de4-04776807040e.arn}/*\"\n      ]\n    }\n  ]\n}"
  role      = module.stackgen_b59373c6-8053-47cb-bee1-68d4b56e6854.name
  role_type = "Reader"
}

module "stackgen_6d0a6766-36f3-4abc-8de4-04776807040e" {
  source                       = "./modules/aws_s3"
  block_public_access          = true
  bucket_name                  = "retroboard-notification-artifacts"
  bucket_policy                = ""
  enable_versioning            = true
  enable_website_configuration = false
  sse_algorithm                = "aws:kms"
  tags                         = {}
  website_error_document       = "404.html"
  website_index_document       = "index.html"
}

module "stackgen_b59373c6-8053-47cb-bee1-68d4b56e6854" {
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

module "stackgen_c7c2b576-a64d-45a5-9134-20fc47bb58dc" {
  source                    = "./modules/aws_ecs"
  cpu_architecture          = "X86_64"
  create_ingress_alb        = true
  ecs_cluster_name          = module.stackgen_fcd6d0c8-badc-4a58-8f66-a707fe893e51.name
  ecs_service_desired_count = 1
  ecs_service_name          = "notification-service"
  ecs_task_container_cpu    = 256
  ecs_task_container_memory = 512
  ecs_task_container_name   = "my-ecs-container"
  ecs_task_container_port   = 80
  ecs_task_image_url        = "nginx:latest"
  environment_variables     = {}
  health_check_path         = "/"
  internal_alb              = false
  network_mode              = "awsvpc"
  operating_system          = "LINUX"
  private_subnet_ids        = []
  protocol                  = "HTTP"
  public_subnet_ids         = []
  region                    = var.region
  tags                      = {}
  task_role_arn             = module.stackgen_b59373c6-8053-47cb-bee1-68d4b56e6854.arn
}

module "stackgen_fcd6d0c8-badc-4a58-8f66-a707fe893e51" {
  source                   = "./modules/aws_ecs_cluster"
  configuration            = []
  name                     = "notification-cluster"
  service_connect_defaults = []
  setting                  = []
  tags                     = {}
}

