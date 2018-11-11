# Define an openstack provider. This should populate with your openstack openrc
# config as given in your variables and override files.
provider "openstack" {
//  user_name     = "${var.openstack_user_name}"
//  tenant_name   = "${var.openstack_project_name}"
//  password      = "${var.openstack_password}"
//  auth_url      = "${var.openstack_auth_url}"
//  region        = "${var.openstack_region}"
//  domain_name   = "${var.openstack_tenant_name}"
}

# Add a new keypair to the cluster using the provided keys. These should
# be the keys you wish to use for operations. They need not be the same ones
# you have registered with openstack previously. They will be deleted from
# openstack upon final resource destruction.
resource "openstack_compute_keypair_v2" "swarm" {
  name = "${var.training_event}-swarm-keypair"
  public_key = "${file(var.openstack_keypair_public_key_path)}"
}

# The openstack network to create for the cluster. Do not use an existing
# netwok name as this will be deleted upon resource destruction.
resource "openstack_networking_network_v2" "swarm" {
  name = "${var.training_event}-swarm-internal-net"
  admin_state_up = "true"
}

# Define the subnet with which to assign the internal cluster ip addresses
resource "openstack_networking_subnet_v2" "swarm" {
  name = "${var.training_event}-swarm-subnet"
  network_id      = "${openstack_networking_network_v2.swarm.id}"
  cidr            = "${var.openstack_network_subnet_cidr}"
  ip_version      = 4
  dns_nameservers = ["8.8.8.8", "8.8.4.4"]
}

# Define security groups for public, private, and local port access.
resource "openstack_compute_secgroup_v2" "swarm" {
  name = "${var.training_event}-swarm-secgroup"
  description = "${var.training_event} swarm security group for all nodes. Allowing communication between swarm nodes and public tcp traffic."

  ###########################
  # Public ports
  ###########################

  # connect to internal network hosts on any tcp port
  # uncomment out to allow tcp traffic to all ports from anywhere
  # rule {
  #   ip_protocol = "tcp"
  #   from_port   = "1"
  #   to_port     = "65535"
  #   cidr        = "0.0.0.0/0"
  # }

  # HTTP traffic
  rule {
    ip_protocol = "tcp"
    from_port   = 80
    to_port     = 80
    cidr        = "0.0.0.0/0"
  }

  # HTTPS traffic
  rule {
    ip_protocol = "tcp"
    from_port   = 443
    to_port     = 443
    cidr        = "0.0.0.0/0"
  }

  # Traefik admin api/webapp
  rule {
    ip_protocol = "tcp"
    from_port   = 28443
    to_port     = 28443
    cidr        = "0.0.0.0/0"
  }

  # SSH to host
  rule {
    ip_protocol = "tcp"
    from_port   = 22
    to_port     = 22
    cidr        = "0.0.0.0/0"
  }

  # SSH to sandbox containers
  rule {
    ip_protocol = "tcp"
    from_port   = 10022
    to_port     = 10022
    cidr        = "0.0.0.0/0"
  }

  # Kibana web app
  rule {
    ip_protocol = "tcp"
    from_port   = 5601
    to_port     = 5601
    cidr        = "0.0.0.0/0"
  }

  # Grafana webapp
  rule {
    ip_protocol = "tcp"
    from_port   = 3000
    to_port     = 3000
    cidr        = "0.0.0.0/0"
  }

  # Portainer docker ui
  rule {
    ip_protocol = "tcp"
    from_port   = 9000
    to_port     = 9000
    cidr        = "0.0.0.0/0"
  }

  # Jupyter HTTP traffic
  rule {
    ip_protocol = "tcp"
    from_port   = 8888
    to_port     = 8888
    cidr        = "0.0.0.0/0"
  }

  # Jenkins HTTP traffic
  rule {
    ip_protocol = "tcp"
    from_port   = 8080
    to_port     = 8080
    cidr        = "0.0.0.0/0"
  }

  ###########################
  # Private network ports
  ###########################

  # connect to internal network hosts on any tcp port
  # comment out to restrict tcp traffic to named ports from the lan
  rule {
    ip_protocol = "tcp"
    from_port   = "1"
    to_port     = "65535"
    cidr        = "${var.openstack_network_subnet_cidr}"
  }

  # swarm udp ingress network
  rule {
    ip_protocol = "udp"
    from_port   = "4789"
    to_port     = "4789"
    cidr        = "${var.openstack_network_subnet_cidr}"
  }

  ###########################
  # Local & Security group ports
  ###########################

  # connect to internal network hosts on any tcp port
  # comment out to restrict tcp traffic to named ports within a security group
  rule {
    ip_protocol = "tcp"
    from_port   = "1"
    to_port     = "65535"
    self        = true
  }

  # swarm tcp network discovery
  rule {
    ip_protocol = "tcp"
    from_port   = "7946"
    to_port     = "7946"
    self        = true
  }

  # swarm udp network discovery
  rule {
    ip_protocol = "udp"
    from_port   = "7946"
    to_port     = "7946"
    self        = true
  }

  # swarm udp ingress network
  rule {
    ip_protocol = "udp"
    from_port   = "4789"
    to_port     = "4789"
    self        = true
  }

  # icmp to self on any port
  rule {
    ip_protocol = "icmp"
    from_port   = "-1"
    to_port     = "-1"
    self        = true
  }
}

# Create a custom router for the swarm
resource "openstack_networking_router_v2" "swarm" {
  name             = "${var.training_event}-swarm-router"
  external_network_id = "${var.openstack_external_gateway_id}"
}

# Create a custom network interface
resource "openstack_networking_router_interface_v2" "swarm" {
  router_id = "${openstack_networking_router_v2.swarm.id}"
  subnet_id = "${openstack_networking_subnet_v2.swarm.id}"
}
