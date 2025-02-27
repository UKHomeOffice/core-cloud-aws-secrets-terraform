data "aws_caller_identity" "this_account" {
}

data "aws_region" "this_region" {
}

module "secret_and_role" {
  source = "./secret_and_role"

  for_each = var.aws_secrets

  aws_secrets = tomap({"${each.key}"=each.value})
  aws_account_id = data.aws_caller_identity.this_account.account_id
  aws_account_region = data.aws_region.this_region.name
}
