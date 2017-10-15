provider "openstack" {
  user_name = "${var.openstack_user_name}"
  tenant_name = "${var.openstack_project_name}"
  password  = "${var.openstack_password}"
  auth_url  = "${var.openstack_auth_url}"
  region      = "${var.openstack_region}"
  domain_name      = "${var.openstack_tenant_name}"
}

resource "openstack_compute_keypair_v2" "keypair" {
  name = "${var.openstack_keypair_name}"
  public_key = "${file(var.openstack_keypair_public_key_path)}"
}

resource "openstack_networking_network_v2" "swarm_tf_network1" {
  name           = "swarm_tf_network_1"
  admin_state_up = "true"
}

resource "openstack_networking_subnet_v2" "swarm_tf_subnet1" {
  name            = "swarm_tf_subnet_1"
  network_id      = "${openstack_networking_network_v2.swarm_tf_network1.id}"
  cidr            = "${var.openstack_network_subnet_cidr}"
  ip_version      = 4
  dns_nameservers = ["8.8.8.8", "8.8.4.4"]
}

# Define security groups for public, private, and local port access.
#
resource "openstack_compute_secgroup_v2" "swarm_tf_secgroup_1" {
  name = "swarm_tf_secgroup_1"
  description = "an example security group"

  ###########################
  # Public ports
  ###########################

  # connect to internal network hosts on any tcp port
  # uncomment out to allow tcp traffic to all ports from anywhere
  rule {
    ip_protocol = "tcp"
    from_port   = "1"
    to_port     = "65535"
    cidr        = "0.0.0.0/0"
  }

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

  # prometheus accessible from network hosts
  rule {
    ip_protocol = "tcp"
    from_port   = 9090
    to_port     = 9090
    cidr        = "${var.openstack_network_subnet_cidr}"
  }

  # elasticsearch accessible from network hosts
  rule {
    ip_protocol = "tcp"
    from_port   = 9200
    to_port     = 9200
    cidr        = "${var.openstack_network_subnet_cidr}"
  }

  # portainer accessible from network hosts
  rule {
    ip_protocol = "tcp"
    from_port   = 9000
    to_port     = 9000
    cidr        = "${var.openstack_network_subnet_cidr}"
  }

  # Kibana accessible from network hosts
  rule {
    ip_protocol = "tcp"
    from_port   = 5601
    to_port     = 5601
    cidr        = "${var.openstack_network_subnet_cidr}"
  }

  # grafana accessible from network hosts
  rule {
    ip_protocol = "tcp"
    from_port   = 3000
    to_port     = 3000
    cidr        = "${var.openstack_network_subnet_cidr}"
  }

  # alertmanager accessible from network hosts
  rule {
    ip_protocol = "tcp"
    from_port   = 9093
    to_port     = 9093
    cidr        = "${var.openstack_network_subnet_cidr}"
  }

  # docker daemon
  rule {
    ip_protocol = "tcp"
    from_port   = 2376
    to_port     = 2376
    cidr        = "${var.openstack_network_subnet_cidr}"
  }

  # swarm tcp network discovery
  rule {
    ip_protocol = "tcp"
    from_port   = "7946"
    to_port     = "7946"
    cidr        = "${var.openstack_network_subnet_cidr}"
  }

  # swarm udp network discovery
  rule {
    ip_protocol = "udp"
    from_port   = "7946"
    to_port     = "7946"
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
  # comment out to restrict tcp traffic to named ports from localhost
  rule {
    ip_protocol = "tcp"
    from_port   = "1"
    to_port     = "65535"
    self        = true
  }

  # connect to localhost on any udp port
  rule {
    ip_protocol = "udp"
    from_port   = "1"
    to_port     = "65535"
    self        = true
  }


  # docker daemon ssl
  rule {
    ip_protocol = "tcp"
    from_port   = 2376
    to_port     = 2376
    self        = true
  }

  # docker daemon http
  rule {
    ip_protocol = "tcp"
    from_port   = 2375
    to_port     = 2375
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

resource "openstack_networking_router_v2" "swarm_tf_router_1" {
  name             = "swarm_tf_router1"
  external_gateway = "${var.openstack_external_gateway_id}"
}

resource "openstack_networking_router_interface_v2" "swarm_tf_router_interface_1" {
  router_id = "${openstack_networking_router_v2.swarm_tf_router_1.id}"
  subnet_id = "${openstack_networking_subnet_v2.swarm_tf_subnet1.id}"
}

resource "openstack_networking_floatingip_v2" "swarm_tf_floatip_manager" {
  pool = "public"
}

resource "openstack_networking_floatingip_v2" "swarm_tf_floatip_managerx" {
  pool = "public"
  count = "${var.swarm_manager_count - 1}"
}

resource "openstack_networking_floatingip_v2" "swarm_tf_floatip_slave" {
  pool = "public"
  count = "${length(var.swarm_slave_count)}"
}

resource "openstack_networking_floatingip_v2" "swarm_tf_floatip_training" {
  pool = "public"
  count = "${length(var.attendees)}"
}
