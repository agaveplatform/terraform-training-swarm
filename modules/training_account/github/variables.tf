variable "username" {
  description = "The username for whom the repository will be created."
}

variable "github_token" {
  description = "The oauth token to connect with our github organization to create training repositories."
}

variable "github_organization" {
  description = "The github organization in which the training repositories will be created."
}

variable "repository_basename" {
  description = "The base name of the repository. This will be prefixed with the training username to create the user's repository name."
}

variable "deployment_public_key" {
  description = "The deployment key to be added to the repository to enable users to push code to their repo by default."
}

variable "wildcard_domain_name" {
  description = "The user subdomain created for the user. This will be used to generate the webhook callback from github"
}
