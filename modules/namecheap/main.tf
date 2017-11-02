
# creates a new user account
resource "null_resource" "dynamic_dns" {

  # # update the wildcard base domain to point to github pages for the repo
  # provisioner "local-exec" {
  #   command = "NC_DDNS_PASS=${var.namecheap_api_token} ${module.path}/namecheap-ddns-update -s '${replace(var.wildcard_domain_name,".agaveplatform.org","")}' -i ${var.server_ip_address} -d agaveplatform.org"
  # }

  # create a user account
  provisioner "local-exec" {
    command = "NC_DDNS_PASS=${var.namecheap_api_token} ${module.path}/namecheap-ddns-update -s '*.${replace(var.wildcard_domain_name,".agaveplatform.org","")}' -i ${var.server_ip_address} -d agaveplatform.org"
  }

}
