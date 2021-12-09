output "created_date" {
  description = "The date the REST API was created"
  value       = module.api_gateway.created_date
}

output "invoke_url" {
  description = "The URL to invoke the REST API"
  value       = module.api_gateway.invoke_url
}
