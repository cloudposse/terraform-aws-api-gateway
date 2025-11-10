provider "aws" {
  region = var.region
}

module "api_gateway" {
  source = "../../"

  openapi_config = {
    openapi = "3.0.1"
    info = {
      title   = "example-custom-principals"
      version = "1.0"
    }
    paths = {
      "/test" = {
        get = {
          x-amazon-apigateway-integration = {
            httpMethod           = "GET"
            payloadFormatVersion = "1.0"
            type                 = "HTTP_PROXY"
            uri                  = "https://ip-ranges.amazonaws.com/ip-ranges.json"
          }
        }
      }
    }
  }

  # Enable logging to test CloudWatch IAM role creation
  logging_level = "INFO"

  # Test custom principals parameter (should use default apigateway.amazonaws.com)
  cloudwatch_log_group_principals = var.cloudwatch_log_group_principals

  context = module.this.context
}
