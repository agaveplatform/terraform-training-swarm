# Provision the swarm managerx node(s)
resource "openstack_compute_instance_v2" "swarm_manager" {
  name                = "swarm-manager-${count.index+1}"
  count               = "${var.swarm_manager_count - 1}"

  image_id            = "${var.openstack_image}"

  flavor_id           = "${var.openstack_flavor["m1_small"]}"
  key_pair            = "${openstack_compute_keypair_v2.swarm.name}"
  security_groups     = ["${openstack_compute_secgroup_v2.swarm.name}"]

  metadata = {
    ssh_user          = "${var.openstack_ssh_username}"
    extra_groups      = "docker_swarm,docker_swarm_manager,manager_node,training_cluster,terraform,${var.training_event}"
    depends_on        = "${openstack_networking_network_v2.swarm.name}"
    python_bin        = "/usr/bin/python3"
    swarm_labels      = "manager"

  }

  network {
    name              = "${openstack_networking_network_v2.swarm.name}"
  }
}

# Assign floating ip to the swarm managers for external connectivity
resource "openstack_compute_floatingip_associate_v2" "swarm_manager" {
  count = "${var.swarm_manager_count - 1}"

  floating_ip = "${element(openstack_networking_floatingip_v2.swarm_manager.*.address, count.index)}"
  instance_id = "${element(openstack_compute_instance_v2.swarm_manager.*.id, count.index)}"
}
