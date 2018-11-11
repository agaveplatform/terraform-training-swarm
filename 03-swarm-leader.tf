# Provision the swarm leader node
resource "openstack_compute_instance_v2" "swarm_leader" {
  name                = "swarm-leader-0"
  count               = 1

  image_id            = "${var.openstack_image}"

  flavor_id           = "${var.openstack_flavor["m1_medium"]}"
  key_pair            = "${openstack_compute_keypair_v2.swarm.name}"
  security_groups     = ["${openstack_compute_secgroup_v2.swarm.name}"]

  metadata = {
    ssh_user          = "${var.openstack_ssh_username}"
    extra_groups      = "docker_swarm,docker_swarm_manager,leader_node,training_cluster,terraform,${var.training_event},traefik"
    depends_on        = "${openstack_networking_network_v2.swarm.name}"
    python_bin        = "/usr/bin/python3"
    swarm_labels      = "leader,traefik"

  }

  network {
    name              = "${openstack_networking_network_v2.swarm.name}"
  }
}

# Assign floating ip to the swarm leader for external connectivity
resource "openstack_compute_floatingip_associate_v2" "swarm_leader" {
  # uncomment to assign a new floating ip with each deployment

  floating_ip = "${var.wildcard_floating_ip_address}"
  instance_id = "${openstack_compute_instance_v2.swarm_leader.id}"
}