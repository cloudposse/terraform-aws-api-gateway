terraform {
  required_version = ">= 0.13"

  required_providers {
    local = {
      source  = "hashicorp/aws"
      version = ">= 3.0"
    }
  }
}
