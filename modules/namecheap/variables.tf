variable "wildcard_domain_name" {
  description = "The wildcard subdomain created for this training event"
}

variable "server_ip_address" {
  description = "Base url of the tenant in which to create accounts"
}

variable "namecheap_api_token" {
  description = "API token for updating namecheap dynamic dns records"
}
