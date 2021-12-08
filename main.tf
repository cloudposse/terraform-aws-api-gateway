resource "aws_api_gateway_rest_api" "this" {
  count = module.this.enabled ? 1 : 0

  name = module.this.id
  body = jsonencode(var.openapi_config)

  endpoint_configuration {
    types = [var.endpoint_type]
  }
}

resource "aws_cloudwatch_log_group" "this" {
  count = module.this.enabled ? 1 : 0
  name  = module.this.id

  tags = module.this.tags
}

resource "aws_api_gateway_deployment" "this" {
  count       = module.this.enabled ? 1 : 0
  rest_api_id = aws_api_gateway_rest_api.this[0].id

  triggers = {
    redeployment = sha1(jsonencode(aws_api_gateway_rest_api.this[0].body))
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_api_gateway_stage" "this" {
  count                = module.this.enabled ? 1 : 0
  deployment_id        = aws_api_gateway_deployment.this[0].id
  rest_api_id          = aws_api_gateway_rest_api.this[0].id
  stage_name           = module.this.stage
  xray_tracing_enabled = var.xray_tracing_enabled

  access_log_settings {
    destination_arn = aws_cloudwatch_log_group.this[0].arn
    format          = replace(var.access_log_format, "\n", "")
  }
}

# Set the logging, metrics and tracing levels for all methods
resource "aws_api_gateway_method_settings" "all" {
  rest_api_id = aws_api_gateway_rest_api.this[0].id
  stage_name  = aws_api_gateway_stage.this[0].stage_name
  method_path = "*/*"

  settings {
    metrics_enabled = var.metrics_enabled
    logging_level   = var.logging_level
  }
}
