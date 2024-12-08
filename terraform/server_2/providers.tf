terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
    }
  }
}

provider "aws" {
  shared_config_files      = ["/Users/josok/.aws/config"]
  shared_credentials_files = ["/Users/josok/.aws/credentials"]
  profile                  = "default" # This is the name of the profile in the credentials file of .aws. It is normally enclosed in
  # Square bracket like this [default]. If a different aws account is being used, you can create 
  # a new credentials file with the profile name of the new account to differentiate between the 
  # two accounts.
}