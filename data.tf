data "aws_caller_identity" "current" {}

data "aws_vpc" "vpc" {
  id = var.vpc_id

  dynamic "filter" {
    for_each = local.vpc_filter

    content {
      name   = filter.value["name"]
      values = filter.value["values"]
    }
  }
}

data "aws_subnets" "subnets" {
  dynamic "filter" {
    for_each = local.subnets_filter

    content {
      name   = filter.value["name"]
      values = filter.value["values"]
    }
  }
}

locals {

  vpc_filter = var.vpc_id == null && length(var.vpc_filter) == 0 ? [
    {
      name   = "tag:Name"
      values = ["${var.environment}-apse2-main"]
    }
  ] : []

  subnets_filter = length(var.subnets_filter) == 0 ? [
    {
      name   = "tag:Name"
      values = ["${var.environment}-apse2-main-secure-*"]
    }
  ] : var.subnets_filter

}
