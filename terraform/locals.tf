locals {
  boards = module.stackgen_c939e17d-3036-4096-9b50-ebc36e69237c
}

locals {
  notification_service_registries = [{
    registry_arn = local.sd.service_arns["notification"]
  }]
}

locals {
  email_queue = module.stackgen_1c652d94-e49a-4571-a084-ed3f17f3c6c3
}

locals {
  alerts = module.stackgen_10d934d4-5ad6-4653-a85e-c6c934eb8f97
}

locals {
  api_iam = module.stackgen_6e5ee8be-2793-433b-bc54-fc93f7698f70
}

locals {
  email_iam = module.stackgen_b2e96a9a-2919-4896-9b13-83acf8323bf2
}

locals {
  api_load_balancers = [{
    target_group_arn = local.alb.target_group_arns["${local.prefix}-api-blue"]
    container_name   = "${local.prefix}-api"
    container_port   = 8000
  }]
}

locals {
  app_load_balancers = [{
    target_group_arn = local.alb.target_group_arns["${local.prefix}-app-blue"]
    container_name   = "${local.prefix}-app"
    container_port   = 3000
  }]
}

locals {
  alb = module.stackgen_e68a4061-a05b-4d3a-93a9-203ae5b448f1
}

locals {
  sd = module.stackgen_12d49d31-f258-452f-959f-e7db67b06651
}

locals {
  email = module.stackgen_6e047b6f-714e-4011-b050-e33d5b0a026c
}

locals {
  prefix = "${var.project}-${var.environment}"
}

locals {
  log_group_arn_pattern = "arn:aws:logs:${var.aws_region}:${var.aws_account_id}:log-group:/ecs/${local.prefix}-*:*"
}

locals {
  email_summary_service_registries = [{
    registry_arn = local.sd.service_arns["email-summary"]
  }]
}

locals {
  ecr_url_prefix = "${var.aws_account_id}.dkr.ecr.${var.aws_region}.amazonaws.com"
}

locals {
  infra = {
    vpc_id             = var.vpc_id
    private_subnet_ids = jsondecode(var.private_subnet_ids)
    public_subnet_ids  = jsondecode(var.public_subnet_ids)
    ecr_repository_urls = {
      "retroboard/api"                  = "${local.ecr_url_prefix}/retroboard/api"
      "retroboard/app"                  = "${local.ecr_url_prefix}/retroboard/app"
      "retroboard/email-summary"        = "${local.ecr_url_prefix}/retroboard/email-summary"
      "retroboard/notification-service" = "${local.ecr_url_prefix}/retroboard/notification-service"
    }
    ecr_repository_arns = {
      "retroboard/api"                  = "arn:aws:ecr:${var.aws_region}:${var.aws_account_id}:repository/retroboard/api"
      "retroboard/app"                  = "arn:aws:ecr:${var.aws_region}:${var.aws_account_id}:repository/retroboard/app"
      "retroboard/email-summary"        = "arn:aws:ecr:${var.aws_region}:${var.aws_account_id}:repository/retroboard/email-summary"
      "retroboard/notification-service" = "arn:aws:ecr:${var.aws_region}:${var.aws_account_id}:repository/retroboard/notification-service"
    }
  }
}

locals {
  alb_listener_rules = [
    { priority = 100, path_patterns = ["/boards*"],        target_group_name = "${local.prefix}-api-blue" },
    { priority = 101, path_patterns = ["/email-summary*"], target_group_name = "${local.prefix}-api-blue" },
    { priority = 102, path_patterns = ["/docs*"],          target_group_name = "${local.prefix}-api-blue" },
  ]
}

locals {
  alb_target_groups = [
    { name = "${local.prefix}-api-blue",  port = 8000, protocol = "HTTP", health_check_path = "/docs", health_check_matcher = "200" },
    { name = "${local.prefix}-api-green", port = 8000, protocol = "HTTP", health_check_path = "/docs", health_check_matcher = "200" },
    { name = "${local.prefix}-app-blue",  port = 3000, protocol = "HTTP", health_check_path = "/",     health_check_matcher = "200" },
    { name = "${local.prefix}-app-green", port = 3000, protocol = "HTTP", health_check_path = "/",     health_check_matcher = "200" },
  ]
}

locals {
  notification_container_defs = [{
    name      = "${local.prefix}-notification"
    image     = "${local.infra.ecr_repository_urls["retroboard/notification-service"]}:latest"
    essential = true
    portMappings = [{ containerPort = 8000, hostPort = 8000, protocol = "tcp" }]
    environment = [
      { name = "SLACK_WEBHOOK_URL", value = var.slack_webhook_url },
      { name = "PORT",              value = "8000" },
    ]
    logConfiguration = {
      logDriver = "awslogs"
      options = {
        "awslogs-group"         = "/ecs/${local.prefix}-notification"
        "awslogs-region"        = var.aws_region
        "awslogs-stream-prefix" = "ecs"
      }
    }
  }]
}

locals {
  api_container_defs = [{
    name      = "${local.prefix}-api"
    image     = "${local.infra.ecr_repository_urls["retroboard/api"]}:latest"
    essential = true
    portMappings = [{ containerPort = 8000, hostPort = 8000, protocol = "tcp" }]
    environment = [
      { name = "AWS_REGION",             value = var.aws_region },
      { name = "DYNAMODB_TABLE_NAME",    value = "${local.prefix}-boards" },
      { name = "EMAILS_SQS_QUEUE",       value = "${local.prefix}-emails" },
      { name = "SLACK_ALERTS_SNS_TOPIC", value = "${local.prefix}-alerts" },
      { name = "CORS_ALLOWED_ORIGINS",   value = "*" },
      { name = "PORT",                   value = "8000" },
    ]
    logConfiguration = {
      logDriver = "awslogs"
      options = {
        "awslogs-group"         = "/ecs/${local.prefix}-api"
        "awslogs-region"        = var.aws_region
        "awslogs-stream-prefix" = "ecs"
      }
    }
  }]
}

locals {
  app_container_defs = [{
    name      = "${local.prefix}-app"
    image     = "${local.infra.ecr_repository_urls["retroboard/app"]}:latest"
    essential = true
    portMappings = [{ containerPort = 3000, hostPort = 3000, protocol = "tcp" }]
    environment = []
    logConfiguration = {
      logDriver = "awslogs"
      options = {
        "awslogs-group"         = "/ecs/${local.prefix}-app"
        "awslogs-region"        = var.aws_region
        "awslogs-stream-prefix" = "ecs"
      }
    }
  }]
}

locals {
  email_summary_container_defs = [{
    name      = "${local.prefix}-email-summary"
    image     = "${local.infra.ecr_repository_urls["retroboard/email-summary"]}:latest"
    essential = true
    portMappings = [{ containerPort = 8000, hostPort = 8000, protocol = "tcp" }]
    environment = [
      { name = "AWS_REGION",               value = var.aws_region },
      { name = "SES_SENDER_EMAIL_ADDRESS", value = var.ses_sender_email },
      { name = "TEMPLATE_NAME",            value = "retroboard-summary" },
      { name = "PORT",                     value = "8000" },
    ]
    logConfiguration = {
      logDriver = "awslogs"
      options = {
        "awslogs-group"         = "/ecs/${local.prefix}-email-summary"
        "awslogs-region"        = var.aws_region
        "awslogs-stream-prefix" = "ecs"
      }
    }
  }]
}

