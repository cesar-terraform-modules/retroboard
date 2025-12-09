module "stackgen_1aff38e1-289c-4d37-a72a-c84d088edee1" {
  source                    = "./modules/aws_ecs"
  cpu_architecture          = "X86_64"
  create_ingress_alb        = true
  ecs_cluster_name          = module.stackgen_4986910e-3572-4a71-a793-804355418b61.name
  ecs_service_desired_count = 1
  ecs_service_name          = "notification-service"
  ecs_task_container_cpu    = 256
  ecs_task_container_memory = 512
  ecs_task_container_name   = "my-ecs-container"
  ecs_task_container_port   = 80
  ecs_task_image_url        = "nginx:latest"
  environment_variables     = {}
  health_check_path         = "/health"
  internal_alb              = false
  network_mode              = "awsvpc"
  operating_system          = "LINUX"
  private_subnet_ids        = ["subnet-0785dd490f8091bc6", "subnet-04bb33ccc84d34fbd", "subnet-0332d2c90f23b6275"]
  protocol                  = "HTTP"
  public_subnet_ids         = ["subnet-0785dd490f8091bc6", "subnet-04bb33ccc84d34fbd", "subnet-0332d2c90f23b6275"]
  region                    = var.region
  tags = {
    env     = "sandbox"
    service = "notification"
  }
  task_role_arn = module.stackgen_d4fc78b3-9091-45a0-98d0-241a0ccbe196.arn
}

module "stackgen_3682f6fd-c017-4a9e-a147-6dffa1d21399" {
  source                                   = "./modules/aws_sns"
  application_failure_feedback_role_arn    = null
  application_success_feedback_role_arn    = null
  application_success_feedback_sample_rate = null
  content_based_deduplication              = null
  delivery_policy                          = null
  display_name                             = "notification-events"
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
    env     = "sandbox"
    service = "notification"
  }
  topic_name                        = "notification-events"
  topic_policy                      = ""
  tracing_config                    = null
  use_custom_kms_key_for_encryption = true
}

module "stackgen_381ef06a-7bc0-4702-a28a-1265f3510c34" {
  source    = "./modules/aws_iam_role_policy"
  name      = "Reader-stackgen_8b7ab2"
  policy    = "{\n  \"Version\": \"2012-10-17\",\n  \"Statement\": [\n    {\n      \"Sid\": \"3682f6fdc0174a9ea1476dffa1d213990\",\n      \"Action\": [\n        \"sns:ListTopics\",\n        \"sns:ListSubscriptionsByTopic\",\n        \"sns:GetTopicAttributes\",\n        \"sns:ListSubscriptions\",\n        \"sns:GetSubscriptionAttributes\"\n      ],\n      \"Effect\": \"Allow\",\n      \"Resource\": [\n        \"${module.stackgen_3682f6fd-c017-4a9e-a147-6dffa1d21399.arn}\"\n      ]\n    }\n  ]\n}"
  role      = module.stackgen_d4fc78b3-9091-45a0-98d0-241a0ccbe196.name
  role_type = "Reader"
}

module "stackgen_4986910e-3572-4a71-a793-804355418b61" {
  source                   = "./modules/aws_ecs_cluster"
  configuration            = []
  name                     = "notification-cluster"
  service_connect_defaults = []
  setting                  = []
  tags = {
    env     = "sandbox"
    service = "notification"
  }
}

module "stackgen_5c427ba3-3dfd-48aa-8c17-cc5a8aeff3d9" {
  source    = "./modules/aws_iam_role_policy"
  name      = "Reader-stackgen_46b080"
  policy    = "{\n  \"Version\": \"2012-10-17\",\n  \"Statement\": [\n    {\n      \"Sid\": \"ba304e4ac67245c5ba7e44ff2df3d30a0\",\n      \"Action\": [\n        \"s3:Get*\",\n        \"s3:List*\"\n      ],\n      \"Effect\": \"Allow\",\n      \"Resource\": [\n        \"${module.stackgen_ba304e4a-c672-45c5-ba7e-44ff2df3d30a.arn}\",\n        \"${module.stackgen_ba304e4a-c672-45c5-ba7e-44ff2df3d30a.arn}/*\"\n      ]\n    }\n  ]\n}"
  role      = module.stackgen_d4fc78b3-9091-45a0-98d0-241a0ccbe196.name
  role_type = "Reader"
}

module "stackgen_ba304e4a-c672-45c5-ba7e-44ff2df3d30a" {
  source                       = "./modules/aws_s3"
  block_public_access          = true
  bucket_name                  = "retroboard-notification-bucket"
  bucket_policy                = ""
  enable_versioning            = true
  enable_website_configuration = false
  sse_algorithm                = "aws:kms"
  tags = {
    env     = "sandbox"
    service = "notification"
  }
  website_error_document = "404.html"
  website_index_document = "index.html"
}

module "stackgen_d4fc78b3-9091-45a0-98d0-241a0ccbe196" {
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

