
locals {
  create_iam_role = module.this.enabled && var.iam_role_arn == null
  role_arn        = module.this.enabled ? var.iam_role_arn == null ? module.role.arn : var.iam_role_arn : null
}

resource "aws_api_gateway_account" "this" {
  count               = module.this.enabled ? 1 : 0
  cloudwatch_role_arn = local.role_arn
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

module "role" {
  source  = "cloudposse/iam-role/aws"
  version = "0.16.1"

  enabled = local.create_iam_role
  #name         = module.iam_role_label.id
  use_fullname = true
  attributes   = ["api", "gateway", "cloudwatch"]

  principals = {
    "Service" : ["apigateway.amazonaws.com"]
  }

  policy_documents = [
    data.aws_iam_policy_document.api_gateway_permissions.json,
  ]

  policy_document_count = 1
  policy_description    = "Allow API Gateway to send logs to CloudWatch IAM policy"
  role_description      = "Allow API Gateway to send logs to CloudWatch"
  permissions_boundary  = var.permissions_boundary
  tags_enabled          = var.iam_tags_enabled

  context = module.this.context
}
