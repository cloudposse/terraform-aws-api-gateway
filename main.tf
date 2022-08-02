locals {
  enabled                = module.this.enabled
  create_rest_api_policy = local.enabled || var.existing_api_gateway_rest_api != "" && var.rest_api_policy != null
  create_log_group       = local.enabled && var.logging_level != "OFF"
  log_group_arn          = local.create_log_group ? module.cloudwatch_log_group.0.log_group_arn : null
  vpc_link_enabled       = local.enabled && length(var.private_link_target_arns) > 0
}

resource "aws_api_gateway_rest_api" "this" {
  count = local.enabled ? 1 : 0

  name = module.this.id
  tags = module.this.tags

  endpoint_configuration {
    types = [var.endpoint_type]
  }
}

resource "aws_api_gateway_resource" "this" {
  count = local.enabled && length(var.path_parts) > 0 ? length(var.path_parts) : 0

  rest_api_id = aws_api_gateway_rest_api.this.*.id[0]
  parent_id   = aws_api_gateway_rest_api.this.*.root_resource_id[0]
  path_part   = element(var.path_parts, count.index)
}

resource "aws_api_gateway_rest_api_policy" "this" {
  count       = local.enabled && local.create_rest_api_policy ? 1 : 0
  rest_api_id = var.existing_api_gateway_rest_api != "" ? var.existing_api_gateway_rest_api : aws_api_gateway_rest_api.this[0].id

  policy = var.rest_api_policy
}

module "cloudwatch_log_group" {
  count   = local.enabled && local.create_log_group ? 1 : 0
  source  = "cloudposse/cloudwatch-logs/aws"
  version = "0.6.5"

  enabled              = local.create_log_group
  iam_tags_enabled     = var.iam_tags_enabled
  permissions_boundary = var.permissions_boundary

  context = module.this.context
}

resource "aws_api_gateway_deployment" "this" {
  count       = local.enabled ? 1 : 0
  rest_api_id = aws_api_gateway_rest_api.this[0].id

  triggers = {
    redeployment = sha1(jsonencode(aws_api_gateway_rest_api.this[0].body))
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_api_gateway_stage" "this" {
  count                = local.enabled ? 1 : 0
  deployment_id        = aws_api_gateway_deployment.this[0].id
  rest_api_id          = aws_api_gateway_rest_api.this[0].id
  stage_name           = var.stage_name != "" ? var.stage_name : module.this.environment
  xray_tracing_enabled = var.xray_tracing_enabled
  tags                 = module.this.tags

  variables = {
    vpc_link_id = local.vpc_link_enabled ? aws_api_gateway_vpc_link.this[0].id : null
  }

  dynamic "access_log_settings" {
    for_each = local.create_log_group ? [1] : []

    content {
      destination_arn = local.log_group_arn
      format          = replace(var.access_log_format, "\n", "")
    }
  }
}

# Set the logging, metrics and tracing levels for all methods
resource "aws_api_gateway_method_settings" "all" {
  count       = local.enabled ? 1 : 0
  rest_api_id = aws_api_gateway_rest_api.this[0].id
  stage_name  = aws_api_gateway_stage.this[0].stage_name
  method_path = "*/*"

  settings {
    metrics_enabled = var.metrics_enabled
    logging_level   = var.logging_level
  }
}

resource "aws_api_gateway_method" "default" {
  rest_api_id   = aws_api_gateway_rest_api.this[0].id
  resource_id   = aws_api_gateway_rest_api.this[0].root_resource_id
  http_method   = "GET"
  authorization = "NONE"
}

resource "aws_api_gateway_model" "this" {
  for_each     = local.enabled && length(var.models) > 0 ? { for s in var.models : s.name => s } : {}
  rest_api_id  = aws_api_gateway_rest_api.this.*.id[0]
  name         = each.value.name
  description  = each.value.description
  content_type = each.value.content_type

  schema = each.value.content_type != "" ? each.value.content_type : <<EOF
{
  "type": "object"
}
EOF
}

resource "aws_api_gateway_gateway_response" "this" {
  for_each            = local.enabled && length(var.gateway_responses) > 0 ? { for s in var.gateway_responses : s.response_type => s } : {}
  rest_api_id         = var.existing_api_gateway_rest_api != "" ? var.existing_api_gateway_rest_api : aws_api_gateway_rest_api.this[0].id
  status_code         = each.value.status_code
  response_type       = each.value.response_type
  response_templates  = length(each.value.response_templates) > 0 ? element(each.value.response_templates, 0) : {}
  response_parameters = length(each.value.response_parameters) > 0 ? element(each.value.response_parameters, 0) : {}
}

# Optionally create a VPC Link to allow the API Gateway to communicate with private resources (e.g. ALB)
resource "aws_api_gateway_vpc_link" "this" {
  count       = local.enabled && local.vpc_link_enabled ? 1 : 0
  name        = module.this.id
  description = "VPC Link for ${module.this.id}"
  target_arns = var.private_link_target_arns
}
