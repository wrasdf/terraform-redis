locals {
  port                        = coalesce(var.port, var.engine == "memcached" ? 11211 : 6379)
  parameter_group_name_result = var.create ? aws_elasticache_parameter_group.this[0].id : var.parameter_group_name
  security_group_ids          = concat(var.security_group_ids, [aws_security_group.this[0].id])
  subnet_group_name           = var.create ? aws_elasticache_subnet_group.this[0].name : var.subnet_group_name
  create_cloudwatch_log_group = var.create && var.engine != "memcached"
  tags                        = merge(var.tags, { terraform-modules = "redis" })
}

resource "aws_elasticache_replication_group" "this" {
  count = var.create ? 1 : 0
  description                 = "Terraform-managed Elasticache Redis"
  replication_group_id        = var.elasticache_cluster_name
  apply_immediately           = var.apply_immediately
  at_rest_encryption_enabled  = var.at_rest_encryption_enabled
  auth_token                  = var.auth_token
  auth_token_update_strategy  = var.auth_token_update_strategy
  auto_minor_version_upgrade  = var.auto_minor_version_upgrade
  automatic_failover_enabled  = var.replicas_per_node_group > 0 ? true : var.automatic_failover_enabled
  cluster_mode                = var.cluster_mode
  data_tiering_enabled        = var.data_tiering_enabled
  engine                      = var.engine
  engine_version              = var.engine_version
  final_snapshot_identifier   = var.final_snapshot_identifier
  global_replication_group_id = var.global_replication_group_id
  ip_discovery                = var.ip_discovery
  kms_key_id                  = var.at_rest_encryption_enabled ? var.kms_key_arn : null

  dynamic "log_delivery_configuration" {
    for_each = { for k, v in var.log_delivery_configuration : k => v if var.engine != "memcached" }

    content {
      destination      = try(log_delivery_configuration.value.create_cloudwatch_log_group, true) && log_delivery_configuration.value.destination_type == "cloudwatch-logs" ? aws_cloudwatch_log_group.this[log_delivery_configuration.key].name : log_delivery_configuration.value.destination
      destination_type = log_delivery_configuration.value.destination_type
      log_format       = log_delivery_configuration.value.log_format
      log_type         = try(log_delivery_configuration.value.log_type, log_delivery_configuration.key)
    }
  }

  maintenance_window          = var.maintenance_window
  multi_az_enabled            = var.replicas_per_node_group > 0 ? true : false
  network_type                = var.network_type
  node_type                   = var.node_type
  notification_topic_arn      = var.notification_topic_arn
  num_cache_clusters          = var.num_cache_clusters
  num_node_groups             = var.num_node_groups
  parameter_group_name        = local.parameter_group_name_result
  port                        = coalesce(var.port, local.port)
  preferred_cache_cluster_azs = var.preferred_cache_cluster_azs
  replicas_per_node_group     = var.replicas_per_node_group

  security_group_names        = var.security_group_names
  security_group_ids          = local.security_group_ids
  snapshot_arns               = var.snapshot_arns
  snapshot_name               = var.snapshot_name
  snapshot_retention_limit    = var.snapshot_retention_limit
  snapshot_window             = var.snapshot_window
  subnet_group_name           = local.subnet_group_name
  transit_encryption_enabled  = var.transit_encryption_enabled
  transit_encryption_mode     = var.transit_encryption_mode
  user_group_ids              = var.user_group_ids

  tags = local.tags
}

resource "aws_cloudwatch_log_group" "this" {
  for_each = { for k, v in var.log_delivery_configuration : k => v if local.create_cloudwatch_log_group && try(v.create_cloudwatch_log_group, true) && try(v.destination_type, "") == "cloudwatch-logs" }

  name              = "/aws/elasticache/${try(each.value.cloudwatch_log_group_name, var.elasticache_cluster_name, "")}"
  retention_in_days = try(each.value.cloudwatch_log_group_retention_in_days, 14)
  kms_key_id        = try(each.value.cloudwatch_log_group_kms_key_id, null)
  skip_destroy      = try(each.value.cloudwatch_log_group_skip_destroy, null)
  log_group_class   = try(each.value.cloudwatch_log_group_class, null)

  tags = merge(local.tags, try(each.value.tags, {}))
}

resource "aws_elasticache_parameter_group" "this" {
  count  = var.create ? 1 : 0
  name   = "${var.elasticache_cluster_name}-parameter-group"
  family = "redis${can(regex("^7", var.engine_version)) ? "7" : substr(var.engine_version, 0, 3)}"

  dynamic "parameter" {
    for_each = var.parameters

    content {
      name  = parameter.value.name
      value = parameter.value.value
    }
  }

  tags = local.tags

  lifecycle {
    create_before_destroy = true
  }

}

resource "aws_security_group" "this" {
  count  = var.create ? 1 : 0
  name   = "${var.elasticache_cluster_name}-elasticache-security-group"
  vpc_id = data.aws_vpc.vpc.id
}

resource "aws_vpc_security_group_ingress_rule" "this" {
  for_each = var.create ? toset(compact(concat([data.aws_vpc.vpc.cidr_block], var.additional_ingress_cidrs))) : []

  security_group_id = aws_security_group.this[0].id
  cidr_ipv4         = each.value
  ip_protocol       = "tcp"
  from_port         = local.port
  to_port           = local.port
}

resource "aws_vpc_security_group_egress_rule" "this" {
  count  = var.create ? 1 : 0
  security_group_id = aws_security_group.this[0].id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = -1
}

resource "aws_elasticache_subnet_group" "this" {
  count       = var.create ? 1 : 0  
  name        = "${var.elasticache_cluster_name}-subnet-group"
  subnet_ids  = data.aws_subnets.subnets.ids
  description = "Subnet group for elasticache"
}