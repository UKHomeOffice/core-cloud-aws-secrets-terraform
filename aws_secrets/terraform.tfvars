
aws_secrets = {
    demo_secret = {
        secret_description = "A secret for demo."
      secret_recovery_window_days = 0 # Deletes the secret immediately on destroy - 30 days if omitted
      session_name_to_allow = "GithubDemoSession" # Can be any string and must be used in the corresponding github action
      github_repos_to_allow = [ # List of repo dictionaries. Refer to the terraform module for more options.
        {
          repo_name = "core-cloud-cosmos-action-tester"
        }]

     tags  = {
            account-code   =   "521835",
            cost-centre    =   "1709144",
            service-id     =   "Dynatrace",
            portfolio-id   =   "CTO",
            project-id     =   "CC"
            }  
     }
}


