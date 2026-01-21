variable "region" {
  type        = string
  description = "AWS region"
}

variable "cloudwatch_log_group_principals" {
  description = "Map of service principals for CloudWatch Logs IAM role"
  type        = map(list(string))
  default = {
    Service = ["apigateway.amazonaws.com"]
  }
}
