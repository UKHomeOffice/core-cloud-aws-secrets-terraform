variable "aws_secrets" {
  type = map(object({
    # secret rotation must be implemented separately *extending this module*
    secret_description          = string               # Description of the secret
    secret_recovery_window_days = optional(number, 30) # Number of days to retain the secret after deletion, for a recovery opportunity. Default is 30 (0 will delete the secret immediately. Refer to - https://docs.aws.amazon.com/secretsmanager/latest/apireference/API_DeleteSecret.html
    session_name_to_allow       = string               # Name of the STS session to feed through github action and used in the IAM role to allow access to the secret
    github_repos_to_allow = optional(list(object({              # List of the git repositories to be allowed access to the secret
      repo_name = string                               # Name of the git repository without https or git@ and without the '.git' suffix
      github_organisation = optional(
        string, "UKHomeOffice" # Name of the github organisation.
      )
      branch_ref = optional(string, "*") # Branch allowed to access the secret; ideally should me 'main'
    })),[])
    iam_roles = optional(list(string),[])     # A list of existing IAM role names which can access this secret.
    tags = object({ # Tags to be applied to the secret 
      account-code = string
      cost-centre  = string
      service-id   = string
      portfolio-id = string
      project-id   = string
    })
  }))
}