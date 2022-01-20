locals {
  enabled                = module.this.enabled
  create_rest_api_policy = local.enabled && var.rest_api_policy != null
  create_log_group       = local.enabled && var.logging_level != "OFF"
  log_group_arn          = local.create_log_group ? module.cloudwatch_log_group.log_group_arn : null
}

resource "aws_api_gateway_rest_api" "this" {
  count = local.enabled ? 1 : 0

  name = module.this.id
  body = jsonencode(var.openapi_config)
  tags = module.this.tags

  endpoint_configuration {
    types = [var.endpoint_type]
  }
}

resource "aws_api_gateway_rest_api_policy" "this" {
  count       = local.create_rest_api_policy ? 1 : 0
  rest_api_id = var.existing_api_gateway_rest_api != "" ? var.existing_api_gateway_rest_api : aws_api_gateway_rest_api.this[0].id

  policy = var.rest_api_policy
}

module "cloudwatch_log_group" {
  source  = "cloudposse/cloudwatch-logs/aws"
  version = "0.6.2"

  enabled = local.create_log_group
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
  stage_name           = module.this.stage
  xray_tracing_enabled = var.xray_tracing_enabled
  tags                 = module.this.tags

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
