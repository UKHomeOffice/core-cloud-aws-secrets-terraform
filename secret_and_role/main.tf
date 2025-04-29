locals {
  secret_name = keys(var.aws_secrets)[0]
}

resource "aws_iam_role" "secret_iam_role" {
  count = length(var.aws_secrets[local.secret_name].github_repos_to_allow) > 0 ? 1 : 0
  name = "RoleToAccess_${local.secret_name}_FromGithub"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      for curr_repo in var.aws_secrets[local.secret_name].github_repos_to_allow : {
        Effect = "Allow"
        Principal = {
          Federated = "arn:aws:iam::${var.aws_account_id}:oidc-provider/token.actions.githubusercontent.com"
        }
        Action = "sts:AssumeRoleWithWebIdentity"
        Condition = {
          StringEquals = {
            "token.actions.githubusercontent.com:aud" = "sts.amazonaws.com"
          }
          StringLike = {
            "sts:RoleSessionName"                     = var.aws_secrets[local.secret_name].session_name_to_allow
            "token.actions.githubusercontent.com:sub" = "repo:${curr_repo.github_organisation}/${curr_repo.repo_name}:${curr_repo.branch_ref}"
          }
        }
      }
    ]
  })
}

resource "aws_kms_key" "secrets" {
  enable_key_rotation = true
}

resource "aws_secretsmanager_secret" "this_secret" {
  name                    = local.secret_name
  description             = var.aws_secrets[local.secret_name].secret_description
  recovery_window_in_days = var.aws_secrets[local.secret_name].secret_recovery_window_days
  kms_key_id              = aws_kms_key.secrets.arn

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        AWS = concat(
          length(aws_iam_role.secret_iam_role) > 0 ? ["arn:aws:iam::${var.aws_account_id}:role/${aws_iam_role.secret_iam_role[0].name}"] : [], 
          formatlist("arn:aws:iam::${var.aws_account_id}:role/%s", var.aws_secrets[local.secret_name].iam_roles)
          )
      }
      Action = [
          "secretsmanager:GetResourcePolicy",
          "secretsmanager:GetSecretValue",
          "secretsmanager:DescribeSecret",
          "secretsmanager:ListSecretVersionIds"
        ],
      Resource = "*"
    }]
  })

  tags = var.aws_secrets[local.secret_name].tags
}

output "secret_id" {
  value = aws_secretsmanager_secret.this_secret.id
}


resource "aws_iam_policy" "access_to_secret_kms" {
  name =  "cc-access-to-kms-${local.secret_name}"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
        {    
            Action = [
              "kms:DescribeKey",
              "kms:Decrypt",
              "kms:ListAliases"
            ]
            Effect = "Allow"
            Resource = aws_kms_key.secrets.arn
        }
      ]
  })
}

resource "aws_iam_role_policy_attachment" "attach_kms_access_policy" {
  count = length(var.aws_secrets[local.secret_name].github_repos_to_allow) > 0 ? 1 : 0
  role = aws_iam_role.secret_iam_role[0].name
  policy_arn = aws_iam_policy.access_to_secret_kms.arn
}

resource "aws_iam_role_policy_attachment" "attach_kms_access_policy_iam_roles" {
  for_each = toset(var.aws_secrets[local.secret_name].iam_roles)
  role = each.key
  policy_arn = aws_iam_policy.access_to_secret_kms.arn
}
