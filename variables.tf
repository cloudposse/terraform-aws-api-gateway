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
  description = "The logging level of the API. One of - OFF, INFO, ERROR"
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

# See https://docs.aws.amazon.com/apigateway/latest/developerguide/apigateway-resource-policies.html for additional
# information on how to configure resource policies.
#
# Example:
# {
#    "Version": "2012-10-17",
#    "Statement": [
#        {
#            "Effect": "Allow",
#            "Principal": "*",
#            "Action": "execute-api:Invoke",
#            "Resource": "arn:aws:execute-api:us-east-1:000000000000:*"
#        },
#        {
#            "Effect": "Deny",
#            "Principal": "*",
#            "Action": "execute-api:Invoke",
#            "Resource": "arn:aws:execute-api:region:account-id:*",
#            "Condition": {
#                "NotIpAddress": {
#                    "aws:SourceIp": "123.4.5.6/24"
#                }
#            }
#        }
#    ]
#}
variable "rest_api_policy" {
  description = "The IAM policy document for the API."
  type        = string
  default     = null
}

variable "description" {
  description = "Description of the REST API. If importing an OpenAPI specification via the body argument, this corresponds to the info.description field. If the argument value is provided and is different than the OpenAPI value, the argument value will override the OpenAPI value."
  type        = string
  default     = null
}

variable "binary_media_types" {
  description = "List of binary media types supported by the REST API. By default, the REST API supports only UTF-8-encoded text payloads. If importing an OpenAPI specification via the body argument, this corresponds to the x-amazon-apigateway-binary-media-types extension. If the argument value is provided and is different than the OpenAPI value, the argument value will override the OpenAPI value."
  type        = list(string)
  default     = null
}

variable "minimum_compression_size" {
  description = "Minimum response size to compress for the REST API. Integer between -1 and 10485760 (10MB). Setting a value greater than -1 will enable compression, -1 disables compression (default). If importing an OpenAPI specification via the body argument, this corresponds to the x-amazon-apigateway-minimum-compression-size extension. If the argument value (except -1) is provided and is different than the OpenAPI value, the argument value will override the OpenAPI value."
  type        = string
  default     = null
}

variable "parameters" {
  description = "Map of customizations for importing the specification in the body argument. For example, to exclude DocumentationParts from an imported API, set ignore equal to documentation. Additional documentation, including other parameters such as basepath, can be found in the API Gateway Developer Guide."
  type        = map(any)
  default     = null
}

variable "api_key_source" {
  description = "Source of the API key for requests. Valid values are HEADER (default) and AUTHORIZER. If importing an OpenAPI specification via the body argument, this corresponds to the x-amazon-apigateway-api-key-source extension. If the argument value is provided and is different than the OpenAPI value, the argument value will override the OpenAPI value."
  type        = string
  default     = null

  validation {
    condition     = contains(["HEADER", "AUTHORIZER"], var.api_key_source)
    error_message = "Valid values for var: logging_level are (HEADER, AUTHORIZER)."
  }
}

variable "disable_execute_api_endpoint" {
  description = "Specifies whether clients can invoke your API by using the default execute-api endpoint. By default, clients can invoke your API with the default https://{api_id}.execute-api.{region}.amazonaws.com endpoint. To require that clients use a custom domain name to invoke your API, disable the default endpoint. Defaults to false. If importing an OpenAPI specification via the body argument, this corresponds to the x-amazon-apigateway-endpoint-configuration extension disableExecuteApiEndpoint property. If the argument value is true and is different than the OpenAPI value, the argument value will override the OpenAPI value."
  type        = bool
  default     = false
}
