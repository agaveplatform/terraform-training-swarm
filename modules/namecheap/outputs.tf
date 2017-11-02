output "wildcard_entry" {
  description = "Resulting wildcard dns entry after the update"
  value = "${host_ip_address} *.${var.wildcard_domain_name}"
}
