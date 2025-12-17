module "stackgen_148c832d-5997-4721-9cb7-d00381c60844" {
  source                    = "./modules/aws_ecs"
  cpu_architecture          = "X86_64"
  create_ingress_alb        = true
  ecs_cluster_name          = module.stackgen_25703056-2b89-4d7e-940d-3b8879a107f5.name
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
  private_subnet_ids        = ["subnet-0048c0bc3d3770ffd", "subnet-04bb33ccc84d34fbd"]
  protocol                  = "HTTP"
  public_subnet_ids         = ["subnet-0f5b2c8b310684a5c", "subnet-0785dd490f8091bc6"]
  region                    = var.region
  tags                      = {}
  task_role_arn             = module.stackgen_c9147ba6-dd2c-44ae-9367-295a7a77b2c9.arn
}

module "stackgen_25703056-2b89-4d7e-940d-3b8879a107f5" {
  source                   = "./modules/aws_ecs_cluster"
  configuration            = []
  name                     = "cuddly-bird-c5in2u"
  service_connect_defaults = []
  setting                  = []
  tags                     = {}
}

module "stackgen_26d13ef2-e32f-4330-9031-23ff60322c3d" {
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

module "stackgen_2d1be002-2df0-48b5-aff3-4c7a46ec6e75" {
  source    = "./modules/aws_iam_role_policy"
  name      = "Reader-stackgen_8b7ab2"
  policy    = "{\n  \"Version\": \"2012-10-17\",\n  \"Statement\": [\n    {\n      \"Sid\": \"26d13ef2e32f4330903123ff60322c3d0\",\n      \"Action\": [\n        \"sns:ListTopics\",\n        \"sns:ListSubscriptionsByTopic\",\n        \"sns:GetTopicAttributes\",\n        \"sns:ListSubscriptions\",\n        \"sns:GetSubscriptionAttributes\"\n      ],\n      \"Effect\": \"Allow\",\n      \"Resource\": [\n        \"${module.stackgen_26d13ef2-e32f-4330-9031-23ff60322c3d.arn}\"\n      ]\n    }\n  ]\n}"
  role      = module.stackgen_c9147ba6-dd2c-44ae-9367-295a7a77b2c9.name
  role_type = "Reader"
}

module "stackgen_84b271c1-8185-4192-a0e2-8bcc7369838a" {
  source                       = "./modules/aws_s3"
  block_public_access          = true
  bucket_name                  = "retroboard-notification-service-5ee0b035"
  bucket_policy                = ""
  enable_versioning            = true
  enable_website_configuration = false
  sse_algorithm                = "aws:kms"
  tags                         = {}
  website_error_document       = "404.html"
  website_index_document       = "index.html"
}

module "stackgen_a0aff547-be2c-4759-984c-48b11e2efefc" {
  source    = "./modules/aws_iam_role_policy"
  name      = "Reader-stackgen_46b080"
  policy    = "{\n  \"Version\": \"2012-10-17\",\n  \"Statement\": [\n    {\n      \"Sid\": \"84b271c181854192a0e28bcc7369838a0\",\n      \"Action\": [\n        \"s3:Get*\",\n        \"s3:List*\"\n      ],\n      \"Effect\": \"Allow\",\n      \"Resource\": [\n        \"${module.stackgen_84b271c1-8185-4192-a0e2-8bcc7369838a.arn}\",\n        \"${module.stackgen_84b271c1-8185-4192-a0e2-8bcc7369838a.arn}/*\"\n      ]\n    }\n  ]\n}"
  role      = module.stackgen_c9147ba6-dd2c-44ae-9367-295a7a77b2c9.name
  role_type = "Reader"
}

module "stackgen_c9147ba6-dd2c-44ae-9367-295a7a77b2c9" {
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

