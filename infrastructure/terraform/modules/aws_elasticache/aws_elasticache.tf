locals {
  final_cluster_id = var.cluster_id
}

# Create the ElastiCache cluster
resource "aws_elasticache_cluster" "this" {
  cluster_id           = local.final_cluster_id
  engine               = var.engine
  node_type            = var.node_type
  num_cache_nodes      = var.engine == "redis" ? 1 : var.num_cache_nodes
  parameter_group_name = aws_elasticache_parameter_group.parameter_group.name
  port                 = var.port
  subnet_group_name    = var.use_vpc ? aws_elasticache_subnet_group.this[0].name : null
  security_group_ids   = var.use_vpc ? var.security_group_ids : []
  dynamic "log_delivery_configuration" {
    for_each = var.enable_redis_log_delivery ? [1] : []
    content {
      destination      = aws_cloudwatch_log_group.elasticache_redis_cloudwatch_log.arn
      log_type         = var.log_type
      destination_type = "cloudwatch-logs"
      log_format       = var.log_format
    }
  }
  az_mode = var.engine == "memcached" ? var.az_mode : "single-az"
  tags    = var.tags
}

# cloudwatch resource for log redirection
resource "aws_cloudwatch_log_group" "elasticache_redis_cloudwatch_log" {
  name              = "/aws/elasticache/${local.final_cluster_id}"
  retention_in_days = var.cloudwatch_retention_in_days
}

# Create an ElastiCache parameter group
resource "aws_elasticache_parameter_group" "parameter_group" {
  name        = "elasticache-parameter-group"
  family      = var.family
  description = "ElastiCache parameter group"
}

resource "aws_elasticache_subnet_group" "this" {
  count      = var.use_vpc ? 1 : 0
  name       = "elasticache-subnet-group"
  subnet_ids = var.subnet_ids
}

resource "aws_elasticache_user" "test" {
  user_id       = var.user_id
  user_name     = var.user_name
  access_string = var.access_string
  engine        = "REDIS"
  passwords     = [var.password]
}



