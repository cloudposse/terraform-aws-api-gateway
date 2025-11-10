output "id" {
  value       = module.api_gateway.id
  description = "The ID of the REST API"
}

output "invoke_url" {
  value       = module.api_gateway.invoke_url
  description = "The URL to invoke the API"
}

output "execution_arn" {
  value       = module.api_gateway.execution_arn
  description = "The execution ARN of the REST API"
}

output "cloudwatch_log_group_arn" {
  value       = module.api_gateway.cloudwatch_log_group_arn
  description = "The ARN of the CloudWatch Log Group"
}

output "cloudwatch_role_arn" {
  value       = module.api_gateway.cloudwatch_role_arn
  description = "The ARN of the IAM role for CloudWatch Logs"
}
