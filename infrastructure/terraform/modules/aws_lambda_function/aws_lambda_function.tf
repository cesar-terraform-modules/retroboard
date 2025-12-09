resource "aws_lambda_function" "this" {
  function_name           = var.function_name
  role                    = var.role
  architectures           = var.architectures
  code_signing_config_arn = var.code_signing_config_arn
  dynamic "dead_letter_config" {
    for_each = var.dead_letter_config
    content {
      target_arn = dead_letter_config.value.target_arn
    }
  }
  description = var.description
  dynamic "environment" {
    for_each = var.environment
    content {
      variables = environment.value.variables
    }
  }
  dynamic "ephemeral_storage" {
    for_each = var.ephemeral_storage
    content {
      size = ephemeral_storage.value.size
    }
  }
  dynamic "file_system_config" {
    for_each = var.file_system_config
    content {
      local_mount_path = file_system_config.value.local_mount_path
      arn              = file_system_config.value.arn
    }
  }
  filename = var.filename
  handler  = var.handler
  dynamic "image_config" {
    for_each = var.image_config
    content {
      command           = image_config.value.command
      working_directory = image_config.value.working_directory
      entry_point       = image_config.value.entry_point
    }
  }
  image_uri   = var.filename != null || var.s3_bucket != null ? null : var.image_uri
  kms_key_arn = var.kms_key_arn
  layers      = var.layers
  dynamic "logging_config" {
    for_each = var.logging_config
    content {
      application_log_level = logging_config.value.application_log_level == "" ? null : logging_config.value.application_log_level
      log_format            = logging_config.value.log_format
      log_group             = logging_config.value.log_group
      system_log_level      = logging_config.value.system_log_level == "" ? null : logging_config.value.system_log_level
    }
  }
  memory_size                        = var.memory_size
  package_type                       = var.package_type
  publish                            = var.publish
  reserved_concurrent_executions     = var.reserved_concurrent_executions
  replace_security_groups_on_destroy = var.replace_security_groups_on_destroy
  replacement_security_group_ids     = var.replacement_security_group_ids
  runtime                            = var.runtime
  s3_bucket                          = var.s3_bucket
  s3_key                             = var.s3_key
  skip_destroy                       = var.skip_destroy
  source_code_hash                   = var.source_code_hash
  dynamic "snap_start" {
    for_each = var.snap_start
    content {
      apply_on = snap_start.value.apply_on
    }
  }
  tags    = var.tags
  timeout = var.timeout
  dynamic "tracing_config" {
    for_each = var.tracing_config
    content {
      mode = tracing_config.value.mode
    }
  }
  dynamic "vpc_config" {
    for_each = var.vpc_config
    content {
      ipv6_allowed_for_dual_stack = vpc_config.value.ipv6_allowed_for_dual_stack
      security_group_ids          = vpc_config.value.security_group_ids
      subnet_ids                  = vpc_config.value.subnet_ids
    }
  }

  dynamic "timeouts" {
    for_each = var.timeouts != null ? [var.timeouts] : []
    content {
      create = lookup(timeouts.value, "create", null)
      delete = lookup(timeouts.value, "delete", null)
      update = lookup(timeouts.value, "update", null)
    }
  }
}

