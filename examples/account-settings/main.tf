provider "aws" {
  region = var.region
}

module "account_settings" {
  source  = "../../modules/account-settings"
  context = module.this.context
}
