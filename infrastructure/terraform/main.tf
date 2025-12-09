module "stackgen_24f0cb41-6ee4-473a-adae-1c995f6a52f6" {
  source                                   = "./modules/aws_sns"
  application_failure_feedback_role_arn    = null
  application_success_feedback_role_arn    = null
  application_success_feedback_sample_rate = null
  content_based_deduplication              = null
  delivery_policy                          = null
  display_name                             = "retroboard-alerts"
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
  topic_name                               = "retroboard-alerts"
  topic_policy                             = ""
  tracing_config                           = "Active"
  use_custom_kms_key_for_encryption        = true
}

module "stackgen_497629e6-7005-4fe8-8607-85fc30f3096c" {
  source                       = "./modules/aws_s3"
  block_public_access          = true
  bucket_name                  = "retroboard-notification-8ff9e4"
  bucket_policy                = ""
  enable_versioning            = true
  enable_website_configuration = false
  sse_algorithm                = "aws:kms"
  tags = {
    service = "notification-notifications"
  }
  website_error_document = "404.html"
  website_index_document = "index.html"
}

module "stackgen_4e8b3570-1972-44dc-9ab3-6cc32aea39c0" {
  source    = "./modules/aws_iam_role_policy"
  name      = "Reader-stackgen_f0f806"
  policy    = "{\n  \"Version\": \"2012-10-17\",\n  \"Statement\": [\n    {\n      \"Sid\": \"0f0ee4b343e54cf3aab16cc3ec26b1d10\",\n      \"Action\": [\n        \"s3:Get*\",\n        \"s3:List*\"\n      ],\n      \"Effect\": \"Allow\",\n      \"Resource\": [\n        \"${module.stackgen_$${module.stackgen_497629e6-7005-4fe8-8607-85fc30f3096c.arn}.arn}\",\n        \"${module.stackgen_0f0ee4b3-43e5-4cf3-aab1-6cc3ec26b1d1.arn}/*\"\n      ]\n    }\n  ]\n}"
  role      = module.stackgen_6ca611db-3e88-4b38-92ef-e73b86864e4f.name
  role_type = "Reader"
}

module "stackgen_5c8885f9-d4bc-40a1-bab8-358f9ce5a3a2" {
  source    = "./modules/aws_iam_role_policy"
  name      = "Reader-stackgen_2b1259"
  policy    = "{\n  \"Version\": \"2012-10-17\",\n  \"Statement\": [\n    {\n      \"Sid\": \"a267db9b0a0742b5b7e117fbcd9bd0b50\",\n      \"Action\": [\n        \"sns:ListTopics\",\n        \"sns:ListSubscriptionsByTopic\",\n        \"sns:GetTopicAttributes\",\n        \"sns:ListSubscriptions\",\n        \"sns:GetSubscriptionAttributes\"\n      ],\n      \"Effect\": \"Allow\",\n      \"Resource\": [\n        \"${module.stackgen_$${module.stackgen_24f0cb41-6ee4-473a-adae-1c995f6a52f6.arn}.arn}\"\n      ]\n    }\n  ]\n}"
  role      = module.stackgen_6ca611db-3e88-4b38-92ef-e73b86864e4f.name
  role_type = "Reader"
}

module "stackgen_6ca611db-3e88-4b38-92ef-e73b86864e4f" {
  source                = "./modules/aws_iam_role"
  assume_role_policy    = "{\n\t\t\"Version\": \"2012-10-17\",\n\t\t\"Statement\":{\n\t\t\t\t\"Action\": \"sts:AssumeRole\",\n\t\t\t\t\"Effect\": \"Allow\",\n\t\t\t\t\"Principal\": {\n\t\t\t\t\t\"Service\": \"eks.amazonaws.com\"\n\t\t\t\t}\n\t\t\t}\n\t}"
  description           = null
  force_detach_policies = true
  inline_policy         = []
  max_session_duration  = null
  name                  = "stackgen_8ff9e4-role"
  path                  = null
  permissions_boundary  = null
  tags                  = null
}

module "stackgen_80036d9e-efc7-44f7-b292-2ae3d20a7e41" {
  source                  = "./modules/aws_lambda_function"
  architectures           = ["x86_64"]
  code_signing_config_arn = null
  dead_letter_config      = []
  description             = null
  environment             = []
  ephemeral_storage = [{
    size = 512
  }]
  file_system_config                 = []
  filename                           = "lambda_function.zip"
  function_name                      = "cesar-demo-sqs-processor"
  handler                            = "index.handler"
  image_config                       = []
  image_uri                          = null
  kms_key_arn                        = null
  layers                             = null
  logging_config                     = []
  memory_size                        = "128"
  package_type                       = "Zip"
  publish                            = false
  replace_security_groups_on_destroy = null
  replacement_security_group_ids     = null
  reserved_concurrent_executions     = -1
  role                               = module.stackgen_eee6e4cb-616d-40e3-91d3-125c1d57e0f3.arn
  runtime                            = "python3.12"
  s3_bucket                          = null
  s3_key                             = null
  skip_destroy                       = null
  snap_start                         = []
  source_code_hash                   = null
  tags = {
    owner = "cesar@stackgen.com"
  }
  timeout        = 3
  timeouts       = null
  tracing_config = []
  vpc_config     = []
}

module "stackgen_94f0408f-2c9b-472b-9a02-1c4ee79a27d2" {
  source                             = "./modules/aws_lambda_event_source_mapping"
  batch_size                         = 10
  bisect_batch_on_function_error     = false
  collection_name                    = null
  database_name                      = null
  enabled                            = true
  event_source_arn                   = module.stackgen_eb215e34-eeaf-44bf-a4c4-266f3f8c48ad.arn
  filter_pattern                     = null
  full_document                      = "Default"
  function_name                      = module.stackgen_80036d9e-efc7-44f7-b292-2ae3d20a7e41.arn
  maximum_batching_window_in_seconds = 0
  maximum_concurrency                = 4
  maximum_record_age_in_seconds      = null
  maximum_retry_attempts             = 2
  on_failure_destination_arn         = null
  parallelization_factor             = 1
  principal                          = null
  queue                              = null
  starting_position                  = "LATEST"
  statement_id                       = null
  tags                               = null
  topic                              = null
}

module "stackgen_9ff8b035-8089-4590-8b86-d3330975958c" {
  source              = "./modules/aws_s3_bucket"
  bucket              = "cesar-bucket"
  force_destroy       = false
  object_lock_enabled = false
  tags = {
    owner = "cesar@stackgen.com"
  }
}

module "stackgen_d65a64cf-52d2-4c9c-b37a-ce288b8208a9" {
  source              = "./modules/aws_kms_key"
  description         = "cesar-demo KMS key for SQS encryption"
  enable_key_rotation = true
  tags = {
    owner = "cesar@stackgen.com"
  }
}

module "stackgen_eb215e34-eeaf-44bf-a4c4-266f3f8c48ad" {
  source                            = "./modules/aws_sqs_queue"
  content_based_deduplication       = false
  deduplication_scope               = "queue"
  delay_seconds                     = 0
  fifo_queue                        = false
  fifo_throughput_limit             = "perQueue"
  kms_data_key_reuse_period_seconds = 300
  kms_master_key_id                 = module.stackgen_d65a64cf-52d2-4c9c-b37a-ce288b8208a9.id
  max_message_size                  = 262144
  message_retention_seconds         = 345600
  name                              = "cesar-demo-queue"
  receive_wait_time_seconds         = 0
  tags = {
    owner = "cesar@stackgen.com"
  }
  visibility_timeout_seconds = 30
}

module "stackgen_eee6e4cb-616d-40e3-91d3-125c1d57e0f3" {
  source                = "./modules/aws_iam_role"
  assume_role_policy    = "{\"Version\":\"2012-10-17\",\"Statement\":[{\"Effect\":\"Allow\",\"Principal\":{\"Service\":\"lambda.amazonaws.com\"},\"Action\":\"sts:AssumeRole\"}]}"
  description           = null
  force_detach_policies = true
  inline_policy         = []
  max_session_duration  = null
  name                  = "cesar-demo-lambda-role"
  path                  = null
  permissions_boundary  = null
  tags = {
    owner = "cesar@stackgen.com"
  }
}

