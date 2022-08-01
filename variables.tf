# See https://docs.aws.amazon.com/apigateway/latest/developerguide/api-gateway-swagger-extensions.html for additional
# configuration information.
variable "openapi_config" {
  description = "The OpenAPI specification for the API"
  type        = any
  default     = {}
}

variable "endpoint_type" {
  type        = string
  description = "The type of the endpoint. One of - PUBLIC, PRIVATE, REGIONAL"
  default     = "REGIONAL"

  validation {
    condition     = contains(["EDGE", "REGIONAL", "PRIVATE"], var.endpoint_type)
    error_message = "Valid values for var: endpoint_type are (EDGE, REGIONAL, PRIVATE)."
  }
}

variable "logging_level" {
  type        = string
  description = "The logging level of the API. One of f- OFF, INFO, ERROR"
  default     = "INFO"

  validation {
    condition     = contains(["OFF", "INFO", "ERROR"], var.logging_level)
    error_message = "Valid values for var: logging_level are (OFF, INFO, ERROR)."
  }
}

variable "metrics_enabled" {
  description = "A flag to indicate whether to enable metrics collection."
  type        = bool
  default     = false
}

variable "xray_tracing_enabled" {
  description = "A flag to indicate whether to enable X-Ray tracing."
  type        = bool
  default     = false
}

variable "existing_api_gateway_rest_api" {
  description = "A flag to use existing api gateway rest api to apply the aws_api_gateway_rest_api_policy.this resource against."
  type        = string
  default     = ""
}

# See https://docs.aws.amazon.com/apigateway/latest/developerguide/set-up-logging.html for additional information
# on how to configure logging.
variable "access_log_format" {
  description = "The format of the access log file."
  type        = string
  default     = <<EOF
  {
	"requestTime": "$context.requestTime",
	"requestId": "$context.requestId",
	"httpMethod": "$context.httpMethod",
	"path": "$context.path",
	"resourcePath": "$context.resourcePath",
	"status": $context.status,
	"responseLatency": $context.responseLatency,
  "xrayTraceId": "$context.xrayTraceId",
  "integrationRequestId": "$context.integration.requestId",
	"functionResponseStatus": "$context.integration.status",
  "integrationLatency": "$context.integration.latency",
	"integrationServiceStatus": "$context.integration.integrationStatus",
  "authorizeResultStatus": "$context.authorize.status",
	"authorizerServiceStatus": "$context.authorizer.status",
	"authorizerLatency": "$context.authorizer.latency",
	"authorizerRequestId": "$context.authorizer.requestId",
  "ip": "$context.identity.sourceIp",
	"userAgent": "$context.identity.userAgent",
	"principalId": "$context.authorizer.principalId",
	"cognitoUser": "$context.identity.cognitoIdentityId",
  "user": "$context.identity.user"
}
  EOF
}

variable "rest_api_policy" {
  description = "The IAM policy document for the API."
  type        = string
  default     = null
}

variable "gateway_responses" {
  description = "(Optional) - A list of objects that contain the API Gateway, Gateway Response for a REST API Gateway."
  type = list(object({
    response_type       = string
    status_code         = string
    response_templates  = list(any)
    response_parameters = list(any)
  }))
}

variable "models" {
  description = "(Optional) - A list of objects that contain the desired Models for a REST API Gateway."
  type = list(object({
    name                = string
    description         = optional(string)
    content_type        = optional(string)
    response_parameters = optional(string)
  }))
}


variable "private_link_target_arns" {
  type        = list(string)
  description = "A list of target ARNs for VPC Private Link"
  default     = []
}

variable "iam_tags_enabled" {
  type        = string
  description = "Enable/disable tags on IAM roles and policies"
  default     = true
}

variable "permissions_boundary" {
  type        = string
  default     = ""
  description = "ARN of the policy that is used to set the permissions boundary for the IAM role"
}

variable "stage_name" {
  type        = string
  default     = ""
  description = "The name of the stage"
}
