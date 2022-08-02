resource "aws_api_gateway_resource" "default" {
  count       = local.enabled ? 1 : 0
  rest_api_id = aws_api_gateway_rest_api.this[0].id
  parent_id   = aws_api_gateway_rest_api.this[0].root_resource_id
  path_part   = "null"
}

resource "aws_api_gateway_method" "default" {
  count         = local.enabled ? 1 : 0
  rest_api_id   = aws_api_gateway_rest_api.this[0].id
  resource_id   = aws_api_gateway_resource.default[0].id
  http_method   = "GET"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "mock" {
  count       = local.enabled ? 1 : 0
  rest_api_id = aws_api_gateway_rest_api.this[0].id
  resource_id = aws_api_gateway_resource.default[0].id
  http_method = aws_api_gateway_method.default[0].http_method
  type        = "MOCK"
}
