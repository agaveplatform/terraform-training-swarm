# Generates a set of RSA keys for a user. This uses the native
# terraform TLS provider and has less config than the sshkeygen module
# version, but works with the default tf image.
resource "tls_private_key" "default" {
  algorithm   = "RSA"
}
