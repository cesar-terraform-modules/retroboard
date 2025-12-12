module "stackgen_030199d6-5fb9-43be-a067-5ae550222c88" {
  source    = "./modules/aws_iam_role_policy"
  name      = "Reader-stackgen_46b080"
  policy    = "{\n  \"Version\": \"2012-10-17\",\n  \"Statement\": [\n    {\n      \"Sid\": \"b21ac45400964286b8ac3082666cb6060\",\n      \"Action\": [\n        \"s3:Get*\",\n        \"s3:List*\"\n      ],\n      \"Effect\": \"Allow\",\n      \"Resource\": [\n        \"${module.stackgen_b21ac454-0096-4286-b8ac-3082666cb606.arn}\",\n        \"${module.stackgen_b21ac454-0096-4286-b8ac-3082666cb606.arn}/*\"\n      ]\n    }\n  ]\n}"
  role      = module.stackgen_142d1963-ce71-4518-baa7-151ad4ba887f.name
  role_type = "Reader"
}

module "stackgen_142d1963-ce71-4518-baa7-151ad4ba887f" {
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

module "stackgen_50a541d0-ee65-4476-8b0c-d874f3297ca1" {
  source                   = "./modules/aws_ecs_cluster"
  configuration            = []
  name                     = "notification-cluster"
  service_connect_defaults = []
  setting                  = []
  tags                     = {}
}

module "stackgen_61d45df9-192d-4d66-bc39-d957d13568ec" {
  source                    = "./modules/aws_ecs"
  cpu_architecture          = "X86_64"
  create_ingress_alb        = true
  ecs_cluster_name          = module.stackgen_50a541d0-ee65-4476-8b0c-d874f3297ca1.name
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
  task_role_arn             = module.stackgen_142d1963-ce71-4518-baa7-151ad4ba887f.arn
}

module "stackgen_62c99a97-4192-4a3c-8e3c-1ef0aa0f6203" {
  source                                   = "./modules/aws_sns"
  application_failure_feedback_role_arn    = null
  application_success_feedback_role_arn    = null
  application_success_feedback_sample_rate = null
  content_based_deduplication              = null
  delivery_policy                          = null
  display_name                             = "notification-events"
  fifo_topic                               = false
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

module "stackgen_b0680b78-6fb1-4067-8d02-9dfe63af7629" {
  source    = "./modules/aws_iam_role_policy"
  name      = "Reader-stackgen_8b7ab2"
  policy    = "{\n  \"Version\": \"2012-10-17\",\n  \"Statement\": [\n    {\n      \"Sid\": \"62c99a9741924a3c8e3c1ef0aa0f62030\",\n      \"Action\": [\n        \"sns:ListTopics\",\n        \"sns:ListSubscriptionsByTopic\",\n        \"sns:GetTopicAttributes\",\n        \"sns:ListSubscriptions\",\n        \"sns:GetSubscriptionAttributes\"\n      ],\n      \"Effect\": \"Allow\",\n      \"Resource\": [\n        \"${module.stackgen_62c99a97-4192-4a3c-8e3c-1ef0aa0f6203.arn}\"\n      ]\n    }\n  ]\n}"
  role      = module.stackgen_142d1963-ce71-4518-baa7-151ad4ba887f.name
  role_type = "Reader"
}

module "stackgen_b21ac454-0096-4286-b8ac-3082666cb606" {
  source                       = "./modules/aws_s3"
  block_public_access          = true
  bucket_name                  = "retroboard-notification-bucket"
  bucket_policy                = ""
  enable_versioning            = true
  enable_website_configuration = false
  sse_algorithm                = "aws:kms"
  tags                         = {}
  website_error_document       = "404.html"
  website_index_document       = "index.html"
}

