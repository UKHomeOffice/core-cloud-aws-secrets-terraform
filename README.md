This module creates just an empty secret with some basic information. The idea is to create the secret with all the required tags and corresponding role(s) with relevant permissions so the secret can be readily accessed from the corresponding github action(s) and/or any other resources through a role.

Referring to the attributes:

* github_repos_to_allow
* iam_roles

of `aws_secrets` variable in (shared_varibles.tf)[./shared_varibles.tf] - they are made optional. A secret can be created with no access by any other resource. 

Either of the github actions/workflows or just a role or both can be provided access. 

Each role name within the `iam_roles` must be an existing (previously created) role.

# Troubleshooting

One may encounter the following error during the apply stage:

```
 Error: attaching IAM Policy (arn:aws:iam::<account>:policy/<policy name>) to IAM Role (<IAM role name>): operation error IAM: AttachRolePolicy, https response error StatusCode: 404, RequestID: 91adecfe-5c05-449d-a168-56786a36f35a, NoSuchEntity: The role with name <IAM role name> cannot be found.
```

when an IAM role is provided access to a secret. This is due to the fact when the secret is given access to role that has not yet been created or the secret has already been given access to a role and the role has been deleted (through the pipeline where it was created).

This has been intentionally left to be broken to enforce housekeeping of the IAM roles on the secret. Therefore when this is encountered, one should remove the IAM role(s) from the secret(s) and run the pipeline again. It is also worth noting that this error may happen after sometime since the IAM role was removed as they are not tightly coupled.

# Further improvements 

Though doesn't support readily this module can easily be extended to configure rotation policies and maintaining the secret values. The implementor is responsible to take sufficient security measures.

Following is an example of implementing rotation policy to one of the secrets:

```
module "secrets" {
  source = <url to this module>

  aws_secrets = <dictionary with the secrets>
}

# If required, code for managing the lambda(s) for secret rotation

# Adding rotation policy to just one secret - for example
resource "aws_secretsmanager_secret_rotation" "example" {
  secret_id           = module.secrets["name_of_the_secret_to_rotate"].secret_id
  rotation_lambda_arn = <lambda arn for the secret rotation>

  rotation_rules {
    automatically_after_days = 30
  }
}
```

Following is an example of managing secret values to one of the secrets:

```
module "secrets" {
  source = <url to this module>

  aws_secrets = <dictionary with the secrets>
}

# Single string value
resource "aws_secretsmanager_secret_version" "example" {
  secret_id     = module.secrets["name_of_the_secret_to_manage"].secret_id
  secret_string = "example-string-to-protect"
}

# Key/value value
resource "aws_secretsmanager_secret_version" "example" {
  secret_id     = module.secrets["name_of_the_secret_to_manage"].secret_id
  secret_string = jsonencode(var.example)
}
```