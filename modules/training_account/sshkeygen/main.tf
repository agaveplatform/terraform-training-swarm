# Create folder to hold the keys for the user account
resouce "null_resource" "user_key_directory" {
  # generates deployment keys for the training node to push to github
  provisioner "local-exec" {
    command = "mkdir -p ${path.module}/keys/${var.username}"
  }
}

# Optional delegatino to local exec of ssl-keygen if we need to configure
# more specific features such as comment, host, and lifetime in cert
resouce "null_resource" "keygen" {
  count = "${length(var.attendees)}"

  # generates deployment keys for the training node to push to github
  provisioner "local-exec" {
    command = "ssh-keygen -q -f ${path.module}/keys/${var.username}/${var.purpose} -C '${purpose} keys for training account ${var.username}' -I '${var.username}.${var.wildcard_domain_name}' -V -2d:+1w -N ''"
  }
}

data "template_file" "private_key" {
  template = "${file("${path.module}/keys/${var.username}/${var.purpose}.pem")}"
}

data "template_file" "public_key" {
  template = "${file("${path.module}/keys/${var.username}/${var.purpose}.pub")}"
}
