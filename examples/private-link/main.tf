provider "aws" {
  region = var.region
}

resource "aws_vpc" "this" {
  cidr_block       = "10.99.0.0/16"
  instance_tenancy = "default"
}

resource "aws_subnet" "private1" {
  vpc_id     = aws_vpc.this.id
  cidr_block = "10.99.1.0/24"
}

resource "aws_subnet" "private2" {
  vpc_id     = aws_vpc.this.id
  cidr_block = "10.99.2.0/24"
}

resource "aws_security_group" "this" {
  name        = "allow_http"
  description = "Allow HTTP inbound traffic"
  vpc_id      = aws_vpc.this.id

  ingress {
    description = "HTTP from VPC"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }


}

resource "aws_lb" "this" {
  name               = module.this.id
  internal           = true
  load_balancer_type = "network"
  subnets            = [aws_subnet.private1.id, aws_subnet.private2.id]

  enable_deletion_protection = false
}

module "api_gateway" {
  source = "../../"

  openapi_config = {
    openapi = "3.0.1"
    info = {
      title   = "example"
      version = "1.0"
    }
    paths = {
      "/path1" = {
        get = {
          x-amazon-apigateway-integration = {
            httpMethod           = "GET"
            payloadFormatVersion = "1.0"
            type                 = "HTTP_PROXY"
            connectionType       = "VPC_LINK"
            connectionId         = "$${stageVariables.vpc_link_id}"
            uri                  = "https://ip-ranges.amazonaws.com/ip-ranges.json"
          }
        }
      }
    }
  }
  logging_level            = var.logging_level
  private_link_target_arns = [aws_lb.this.arn]
  context                  = module.this.context
}
