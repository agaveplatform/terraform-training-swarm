output "username" {
  description = "Username of training account"
  value = "${var.username}"
}

output "github_private_key" {
  description = "Private ssh deploy key for github"
  value = "${module.deployment_keys.private_key}"
}

output "github_public_key" {
  description = "Public ssh deploy key for github"
  value = "${module.deployment_keys.public_key}"
}

output "sandbox_private_key" {
  description = "Private ssh login key for sandbox"
  value = "${module.sandbox_keys.private_key}"
}

output "sandbox_public_key" {
  description = "Public ssh login key for sandbox"
  value = "${module.sandbox_keys.public_key}"
}

output "ssh_clone_url" {
  description = "URL to clone the Github repository via ssh"
  value = "${module.github.ssh_clone_url}"
}

output "repository_name" {
  description = "Name of the Github repository created"
  value = "${module.github.repository_name}"
}

output "repository_webhook_url" {
  description = "Webhook url registered to the Github repository"
  value = "${module.github.repository_webhook_url}"
}
