
locals {
  create_iam_role = module.this.enabled && var.iam_role_arn == null
  role_arn        = module.this.enabled ? var.iam_role_arn == null ? aws_iam_role.api_gateway_cloudwatch[0].arn : var.iam_role_arn : null
}

resource "aws_api_gateway_account" "this" {
  count               = module.this.enabled ? 1 : 0
  cloudwatch_role_arn = aws_iam_role.api_gateway_cloudwatch[0].arn
}

resource "aws_iam_role" "api_gateway_cloudwatch" {
  count              = local.create_iam_role ? 1 : 0
  name               = "api_gateway_cloudwatch_global"
  assume_role_policy = data.aws_iam_policy_document.assume_role_policy.json
}

data "aws_iam_policy_document" "assume_role_policy" {
  statement {
    sid    = "AllowAssumeRoleByAPIGW"
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["apigateway.amazonaws.com"]
    }
    actions = ["sts:AssumeRole"]
  }
}

data "aws_iam_policy_document" "api_gateway_permissions" {
  statement {
    sid    = "AllowAPIGatwayToCloudwatch"
    effect = "Allow"
    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:DescribeLogGroups",
      "logs:DescribeLogStreams",
      "logs:PutLogEvents",
      "logs:GetLogEvents",
      "logs:FilterLogEvents"
    ]
    resources = ["*"]
  }
}

resource "aws_iam_role_policy" "cloudwatch" {
  count  = module.this.enabled ? 1 : 0
  name   = "default"
  role   = aws_iam_role.api_gateway_cloudwatch[0].id
  policy = data.aws_iam_policy_document.api_gateway_permissions.json
}
