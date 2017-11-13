output "private_key" {
  description = "Private ssh key"
  value = "${tls_private_key.default.private_key_pem}"
}

output "public_key" {
  description = "Public ssh key"
  value = "${tls_private_key.default.public_key_openssh}"
}
