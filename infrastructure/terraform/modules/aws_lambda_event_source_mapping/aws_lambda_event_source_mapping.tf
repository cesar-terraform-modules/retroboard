resource "aws_lambda_event_source_mapping" "this" {
  # common for all event sources
  event_source_arn  = var.event_source_arn
  function_name     = var.function_name
  starting_position = var.starting_position
  batch_size        = var.batch_size
  enabled           = var.enabled
  tags              = var.tags

  # for MSK
  topics = [var.topic]

  # for MQ
  queues = [var.queue]

  # for kinesis and dynamodb
  bisect_batch_on_function_error = var.bisect_batch_on_function_error
  maximum_record_age_in_seconds  = var.maximum_record_age_in_seconds
  maximum_retry_attempts         = var.maximum_retry_attempts
  parallelization_factor         = var.parallelization_factor
  function_response_types        = ["ReportBatchItemFailures"]

  # for kinsesis dynamodb and kafka
  destination_config {
    on_failure {
      destination_arn = var.on_failure_destination_arn
    }
  }
  maximum_batching_window_in_seconds = var.maximum_batching_window_in_seconds

  # for SQS,kinesis and dynamodb
  filter_criteria {
    filter {
      pattern = var.filter_pattern
    }
  }

  # for dynamodb
  document_db_event_source_config {
    collection_name = var.collection_name
    database_name   = var.database_name
    full_document   = var.full_document
  }
  # for SQS 
  scaling_config {
    maximum_concurrency = var.maximum_concurrency
  }
}

resource "aws_lambda_permission" "name" {
  statement_id  = var.statement_id
  action        = "lambda:InvokeFunction"
  function_name = var.function_name
  principal     = var.principal
  source_arn    = var.event_source_arn
}