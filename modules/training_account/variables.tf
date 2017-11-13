variable "username" {
  description = "The username for whom the training account will be created."
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

variable "wildcard_domain_name" {
  description = "The user subdomain created for the user. This will be used to generate the webhook callback from github"
}
