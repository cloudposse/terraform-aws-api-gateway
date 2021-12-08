provider "aws" {
  region = var.region
}

module "example" {
  source  = "../../modules/account-settings"
  context = module.this.context
}
