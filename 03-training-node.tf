# Provision the training node(s)
resource "openstack_compute_instance_v2" "swarm_training" {
  name                = "training-node-${var.attendees[count.index]}"
  count               = "${length(var.attendees)}"

  image_id            = "${var.openstack_image}"

  flavor_id           = "${var.openstack_flavor["m1_small"]}"
  key_pair            = "${openstack_compute_keypair_v2.swarm.name}"
  security_groups     = ["${openstack_compute_secgroup_v2.swarm.name}"]

  metadata = {
    ssh_user          = "${var.openstack_ssh_username}"
    extra_groups      = "docker_swarm,docker_swarm_worker,training_node,training_cluster,terraform,${var.training_event},${var.attendees[count.index]}"
    depends_on        = "${openstack_networking_network_v2.swarm.name}"
    python_bin        = "/usr/bin/python3"
    swarm_labels      = "training-node-${var.attendees[count.index]},${var.attendees[count.index]},training_node"
    training_user     = "${var.attendees[count.index]}"
  }

  network {
    name              = "${openstack_networking_network_v2.swarm.name}"
  }
}

# Assign floating ip to the training nodes for external connectivity
resource "openstack_compute_floatingip_associate_v2" "swarm_training" {
  count = "${length(var.attendees)}"

  floating_ip = "${element(openstack_networking_floatingip_v2.swarm_training.*.address, count.index)}"
  instance_id = "${element(openstack_compute_instance_v2.swarm_training.*.id, count.index)}"
}
