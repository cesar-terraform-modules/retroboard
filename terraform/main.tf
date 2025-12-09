module "stackgen_22c4589f-a8f9-4352-b78a-1b4dff2ed203" {
  source    = "./modules/aws_iam_role_policy"
  name      = "Reader-stackgen_46b080"
  policy    = "{\n  \"Version\": \"2012-10-17\",\n  \"Statement\": [\n    {\n      \"Sid\": \"3894de3627c84bd08059718518fad4b30\",\n      \"Action\": [\n        \"s3:Get*\",\n        \"s3:List*\"\n      ],\n      \"Effect\": \"Allow\",\n      \"Resource\": [\n        \"${module.stackgen_3894de36-27c8-4bd0-8059-718518fad4b3.arn}\",\n        \"${module.stackgen_3894de36-27c8-4bd0-8059-718518fad4b3.arn}/*\"\n      ]\n    }\n  ]\n}"
  role      = module.stackgen_b88a52b5-ed97-4550-b33c-28f381f5adc5.name
  role_type = "Reader"
}

module "stackgen_2cca4671-bba7-4054-a193-38772afa5ad2" {
  source    = "./modules/aws_iam_role_policy"
  name      = "Reader-stackgen_8b7ab2"
  policy    = "{\n  \"Version\": \"2012-10-17\",\n  \"Statement\": [\n    {\n      \"Sid\": \"3aad5277d7cb4508ad0901bf610ee5ce0\",\n      \"Action\": [\n        \"sns:ListTopics\",\n        \"sns:ListSubscriptionsByTopic\",\n        \"sns:GetTopicAttributes\",\n        \"sns:ListSubscriptions\",\n        \"sns:GetSubscriptionAttributes\"\n      ],\n      \"Effect\": \"Allow\",\n      \"Resource\": [\n        \"${module.stackgen_3aad5277-d7cb-4508-ad09-01bf610ee5ce.arn}\"\n      ]\n    }\n  ]\n}"
  role      = module.stackgen_b88a52b5-ed97-4550-b33c-28f381f5adc5.name
  role_type = "Reader"
}

module "stackgen_3894de36-27c8-4bd0-8059-718518fad4b3" {
  source                       = "./modules/aws_s3"
  block_public_access          = true
  bucket_name                  = "notification-service-artifacts"
  bucket_policy                = ""
  enable_versioning            = true
  enable_website_configuration = false
  sse_algorithm                = "aws:kms"
  tags = {
    app = "notification-service"
  }
  website_error_document = "404.html"
  website_index_document = "index.html"
}

module "stackgen_3aad5277-d7cb-4508-ad09-01bf610ee5ce" {
  source                                   = "./modules/aws_sns"
  application_failure_feedback_role_arn    = null
  application_success_feedback_role_arn    = null
  application_success_feedback_sample_rate = null
  content_based_deduplication              = null
  delivery_policy                          = null
  display_name                             = "notification-service"
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
  topic_name                               = "notification-service-topic"
  topic_policy                             = ""
  tracing_config                           = null
  use_custom_kms_key_for_encryption        = true
}

module "stackgen_6fbacb14-58db-4f34-a733-6060616b3f10" {
  source                   = "./modules/aws_ecs_cluster"
  configuration            = []
  name                     = "notification-ecs-cluster"
  service_connect_defaults = []
  setting                  = []
  tags = {
    app = "notification-service"
  }
}

module "stackgen_b88a52b5-ed97-4550-b33c-28f381f5adc5" {
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

module "stackgen_e22b8dc5-8a71-47d5-b797-029ea8eca11b" {
  source                    = "./modules/aws_ecs"
  cpu_architecture          = "X86_64"
  create_ingress_alb        = true
  ecs_cluster_name          = module.stackgen_6fbacb14-58db-4f34-a733-6060616b3f10.name
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
  task_role_arn             = module.stackgen_b88a52b5-ed97-4550-b33c-28f381f5adc5.arn
}

