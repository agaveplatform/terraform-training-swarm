output "username" {
  description = "Username of training account"
  value = "${var.username}"
}

output "github_deployment_key" {
  description = "Private ssh deploy key for github"
  value = "${var.deployment_public_key}"
}

output "ssh_clone_url" {
  description = "URL to access the training account github repository"
  value = "${github_repository.training.ssh_clone_url}"
}

output "repository_name" {
  description = "Name of the repository created"
  value = "${github_repository.training.name}"
}

output "repository_webhook_url" {
  description = "Webhook url registered to the repository"
  value = "${github_repository_webhook.training.url}"
}
