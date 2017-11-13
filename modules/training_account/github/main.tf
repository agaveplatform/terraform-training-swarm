# Provider block for github. This is where we provide orgnaization and auth
# details to connect to the training organization
provider "github" {
  token        = "${var.github_token}"
  organization = "${var.github_organization}"
}


# Creates a github repository for each attendee. The training repo will be a
# blank repository to which we will add the training application code.
resource "github_repository" "training" {
  name        = "${var.username}-${var.repository_basename}"
  description = "Fork of ${var.repository_basename}"
  homepage_url = "https://${var.username}.${var.wildcard_domain_name}"

  private = false
}

# adds each attendee's public deployment key to the github repo we just created
# for them. This allows them to push code changes to their own git repository.
resource "github_repository_deploy_key" "training" {
  title = "${var.username}.${var.wildcard_domain_name}"
  repository = "${github_repository.training.name}"
  key = "${var.deployment_public_key}"
  read_only = "false"
}

# adds push webhook to the attendee's github repository to tell their Jenkins
# server when a new commit is pushed. The attendee's jenkins server is running
# under the same vanity url as their notebook, and proxied by the global Traefik
# server. To avoid namespace collisions and properly map ports, Jenkins runs on
# the /jenkins subpath.
resource "github_repository_webhook" "training" {
  repository = "${github_repository.training.name}"

  name = "web"

  configuration {
    url          = "https://${var.username}.${var.wildcard_domain_name}/jenkins"
    content_type = "form"
    insecure_ssl = true
  }

  active = false

  events = ["push"]
}
