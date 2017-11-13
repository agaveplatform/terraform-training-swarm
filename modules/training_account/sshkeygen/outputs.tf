output "private_key" {
  description = "Private ssh key"
  value = "${data.template_file.private_key.rendered}"
}

output "private_key_path" {
  description = "Private ssh key file"
  value = "${path.module}/keys/${var.username}/${var.purpose}.pem"
}

output "public_key" {
  description = "Public ssh key"
  value = "${data.template_file.public_key.rendered}"
}

output "public_key_path" {
  description = "Public ssh key"
  value = "${path.module}/keys/${var.username}/${var.purpose}.pub"
}
