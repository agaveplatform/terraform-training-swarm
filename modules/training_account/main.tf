module "deployment_keys" {
  source = "${module.path}/tfkeygen"
}

module "sandbox_keys" {
  source = "${module.path}/tfkeygen"
}

module "github" {
  source = "${module.path}/github"

  username = "${var.username}"
  wildcard_domain_name = "${var.wildcard_domain_name}"
  repository_basename = "${var.repository_basename}"
  github_organization = "${var.github_organization}"
  github_token = "${var.github_token}"
  deployment_public_key = "${module.deployment_keys.public_key}"
}
