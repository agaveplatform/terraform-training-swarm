variable "username" {
  description = "The username for whom the training account will be created. Unused unless using native ssh-keygen callout."
  default = "training"
}

variable "purpose" {
  description = "The purpose of the generated key. Should be github or sandbox. Unused unless using native ssh-keygen callout."
  default = "sandbox"
}

variable "wildcard_domain_name" {
  description = "The wildcard subdomain created for this training event. Unused unless using native ssh-keygen callout."
  default = "training.agaveplatform.org"
}
