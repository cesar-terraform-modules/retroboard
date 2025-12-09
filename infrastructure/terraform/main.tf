module "stackgen_40703344-9d76-43c5-914f-8eb88472e827" {
  source                       = "./modules/aws_s3"
  block_public_access          = true
  bucket_name                  = "retroboard-notification-us-east-2"
  bucket_policy                = ""
  enable_versioning            = true
  enable_website_configuration = false
  sse_algorithm                = "aws:kms"
  tags = {
    app = "retroboard-notification"
  }
  website_error_document = "404.html"
  website_index_document = "index.html"
}

module "stackgen_41c7a608-d5ec-4cd1-b3a4-0656a948976e" {
  source                    = "./modules/aws_ecs"
  cpu_architecture          = "X86_64"
  create_ingress_alb        = true
  ecs_cluster_name          = module.stackgen_5b60a21d-d9e5-4481-93b1-36e00cbbbd2b.name
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
  private_subnet_ids        = ["subnet-0785dd490f8091bc6", "subnet-04bb33ccc84d34fbd", "subnet-0332d2c90f23b6275"]
  protocol                  = "HTTP"
  public_subnet_ids         = ["subnet-0785dd490f8091bc6", "subnet-04bb33ccc84d34fbd", "subnet-0332d2c90f23b6275"]
  region                    = var.region
  tags = {
    app = "retroboard-notification"
  }
  task_role_arn = module.stackgen_eed1e39f-3e3c-4287-b1cb-62e853c81c28.arn
}

module "stackgen_5b60a21d-d9e5-4481-93b1-36e00cbbbd2b" {
  source                   = "./modules/aws_ecs_cluster"
  configuration            = []
  name                     = "notification-cluster"
  service_connect_defaults = []
  setting                  = []
  tags = {
    app = "retroboard-notification"
  }
}

module "stackgen_9f5aa1d4-c700-4e3d-95b4-07687ed32094" {
  source                                   = "./modules/aws_sns"
  application_failure_feedback_role_arn    = null
  application_success_feedback_role_arn    = null
  application_success_feedback_sample_rate = null
  content_based_deduplication              = null
  delivery_policy                          = null
  display_name                             = "Notification Events"
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
    app = "retroboard-notification"
  }
  topic_name                        = "notification-events"
  topic_policy                      = ""
  tracing_config                    = "PassThrough"
  use_custom_kms_key_for_encryption = true
}

module "stackgen_bdefcaf7-5fd6-412e-80a9-b7c2e79231a4" {
  source    = "./modules/aws_iam_role_policy"
  name      = "Reader-stackgen_8b7ab2"
  policy    = "{\n  \"Version\": \"2012-10-17\",\n  \"Statement\": [\n    {\n      \"Sid\": \"9f5aa1d4c7004e3d95b407687ed320940\",\n      \"Action\": [\n        \"sns:ListTopics\",\n        \"sns:ListSubscriptionsByTopic\",\n        \"sns:GetTopicAttributes\",\n        \"sns:ListSubscriptions\",\n        \"sns:GetSubscriptionAttributes\"\n      ],\n      \"Effect\": \"Allow\",\n      \"Resource\": [\n        \"${module.stackgen_9f5aa1d4-c700-4e3d-95b4-07687ed32094.arn}\"\n      ]\n    }\n  ]\n}"
  role      = module.stackgen_eed1e39f-3e3c-4287-b1cb-62e853c81c28.name
  role_type = "Reader"
}

module "stackgen_e9095d27-f5b5-405e-ab40-3c13bc06bcf4" {
  source    = "./modules/aws_iam_role_policy"
  name      = "Reader-stackgen_46b080"
  policy    = "{\n  \"Version\": \"2012-10-17\",\n  \"Statement\": [\n    {\n      \"Sid\": \"407033449d7643c5914f8eb88472e8270\",\n      \"Action\": [\n        \"s3:Get*\",\n        \"s3:List*\"\n      ],\n      \"Effect\": \"Allow\",\n      \"Resource\": [\n        \"${module.stackgen_40703344-9d76-43c5-914f-8eb88472e827.arn}\",\n        \"${module.stackgen_40703344-9d76-43c5-914f-8eb88472e827.arn}/*\"\n      ]\n    }\n  ]\n}"
  role      = module.stackgen_eed1e39f-3e3c-4287-b1cb-62e853c81c28.name
  role_type = "Reader"
}

module "stackgen_eed1e39f-3e3c-4287-b1cb-62e853c81c28" {
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

