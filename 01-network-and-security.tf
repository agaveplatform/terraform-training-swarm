# Define an openstack provider. This should populate with your openstack openrc
# config as given in your variables and override files.
provider "openstack" {
  user_name     = "${var.openstack_user_name}"
  tenant_name   = "${var.openstack_project_name}"
  password      = "${var.openstack_password}"
  auth_url      = "${var.openstack_auth_url}"
  region        = "${var.openstack_region}"
  domain_name   = "${var.openstack_tenant_name}"
}

# Add a new keypair to the cluster using the provided keys. These should
# be the keys you wish to use for operations. They need not be the same ones
# you have registered with openstack previously. They will be deleted from
# openstack upon final resource destruction.
resource "openstack_compute_keypair_v2" "keypair" {
  name = "${var.openstack_keypair_name}"
  public_key = "${file(var.openstack_keypair_public_key_path)}"
}


resource "random_id" "network" {
  keepers = {
    # Generate a new id each time we switch tenants
    openstack_network_name         = "${var.openstack_network_name}"
    openstack_network_subnet_name  = "${var.openstack_network_subnet_name}"
    openstack_secgroup             = "${var.openstack_secgroup}"
    openstack_router               = "${var.openstack_router}"
  }

  byte_length = 8
}

# The openstack network to create for the cluster. Do not use an existing
# netwok name as this will be deleted upon resource destruction.
resource "openstack_networking_network_v2" "swarm_tf_network1" {
  name           = "${random_id.network.keepers.openstack_network_name}"
  admin_state_up = "true"
}

# Define the subnet with which to assign the internal cluster ip addresses
resource "openstack_networking_subnet_v2" "swarm_tf_subnet1" {
  name            = "${random_id.network.keepers.openstack_network_subnet_name}"
  network_id      = "${openstack_networking_network_v2.swarm_tf_network1.id}"
  cidr            = "${var.openstack_network_subnet_cidr}"
  ip_version      = 4
  dns_nameservers = ["8.8.8.8", "8.8.4.4"]
}

# Define security groups for public, private, and local port access.
resource "openstack_compute_secgroup_v2" "swarm_tf_secgroup_1" {
  name = "${random_id.network.keepers.openstack_secgroup}"
  description = "Common swarm security group for all nodes. Allowing communication between swarm nodes and public tcp traffic."

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

  # # prometheus accessible from network hosts
  # rule {
  #   ip_protocol = "tcp"
  #   from_port   = 9090
  #   to_port     = 9090
  #   cidr        = "${var.openstack_network_subnet_cidr}"
  # }
  #
  # # elasticsearch accessible from network hosts
  # rule {
  #   ip_protocol = "tcp"
  #   from_port   = 9200
  #   to_port     = 9200
  #   cidr        = "${var.openstack_network_subnet_cidr}"
  # }
  #
  # # portainer accessible from network hosts
  # rule {
  #   ip_protocol = "tcp"
  #   from_port   = 9000
  #   to_port     = 9000
  #   cidr        = "${var.openstack_network_subnet_cidr}"
  # }
  #
  # # Kibana accessible from network hosts
  # rule {
  #   ip_protocol = "tcp"
  #   from_port   = 5601
  #   to_port     = 5601
  #   cidr        = "${var.openstack_network_subnet_cidr}"
  # }
  #
  # # grafana accessible from network hosts
  # rule {
  #   ip_protocol = "tcp"
  #   from_port   = 3000
  #   to_port     = 3000
  #   cidr        = "${var.openstack_network_subnet_cidr}"
  # }
  #
  # # alertmanager accessible from network hosts
  # rule {
  #   ip_protocol = "tcp"
  #   from_port   = 9093
  #   to_port     = 9093
  #   cidr        = "${var.openstack_network_subnet_cidr}"
  # }
  #
  # # docker daemon
  # rule {
  #   ip_protocol = "tcp"
  #   from_port   = 2376
  #   to_port     = 2376
  #   cidr        = "${var.openstack_network_subnet_cidr}"
  # }
  #
  # # swarm tcp network discovery
  # rule {
  #   ip_protocol = "tcp"
  #   from_port   = "7946"
  #   to_port     = "7946"
  #   cidr        = "${var.openstack_network_subnet_cidr}"
  # }
  #
  # # swarm udp network discovery
  # rule {
  #   ip_protocol = "udp"
  #   from_port   = "7946"
  #   to_port     = "7946"
  #   cidr        = "${var.openstack_network_subnet_cidr}"
  # }

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
  #
  # # connect to localhost on any udp port
  # rule {
  #   ip_protocol = "udp"
  #   from_port   = "1"
  #   to_port     = "65535"
  #   self        = true
  # }
  #
  #
  # # docker daemon ssl
  # rule {
  #   ip_protocol = "tcp"
  #   from_port   = 2376
  #   to_port     = 2376
  #   self        = true
  # }
  #
  # # docker daemon http
  # rule {
  #   ip_protocol = "tcp"
  #   from_port   = 2375
  #   to_port     = 2375
  #   self        = true
  # }

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
resource "openstack_networking_router_v2" "swarm_tf_router_1" {
  name             = "${random_id.network.keepers.openstack_router}"
  external_gateway = "${var.openstack_external_gateway_id}"
}

# Create a custom network interface
resource "openstack_networking_router_interface_v2" "swarm_tf_router_interface_1" {
  router_id = "${openstack_networking_router_v2.swarm_tf_router_1.id}"
  subnet_id = "${openstack_networking_subnet_v2.swarm_tf_subnet1.id}"
}

# Create a floating ip address for the swarm leader
#resource "openstack_networking_floatingip_v2" "swarm_tf_floatip_manager" {
#  pool = "public"
#}

# Create a floating ip address for the swarm manager nodes
resource "openstack_networking_floatingip_v2" "swarm_tf_floatip_managerx" {
  pool = "public"
  count = "${var.swarm_manager_count - 1}"
}

# Create a floating ip address for the swarm slave nodes
resource "openstack_networking_floatingip_v2" "swarm_tf_floatip_slave" {
  pool = "public"
  count = "${length(var.swarm_slave_count)}"
}

# Create a floating ip address for the training nodes
resource "openstack_networking_floatingip_v2" "swarm_tf_floatip_training" {
  pool = "public"
  count = "${length(var.attendees)}"
}
