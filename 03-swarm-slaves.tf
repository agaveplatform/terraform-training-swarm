# Provision the swarm worker node(s)
resource "openstack_compute_instance_v2" "swarm_worker" {
  name                = "swarm-worker-${count.index}"
  count               = "${var.swarm_worker_count}"

  image_id            = "${var.openstack_image}"

  flavor_id           = "${var.openstack_flavor["m1_medium"]}"
  key_pair            = "${openstack_compute_keypair_v2.swarm.name}"
  security_groups     = ["${openstack_compute_secgroup_v2.swarm.name}"]

  metadata = {
    ssh_user          = "${var.openstack_ssh_username}"
    extra_groups      = "docker_swarm,docker_swarm_worker,worker_node,terraform,${var.training_event},gitlab"
    depends_on        = "${openstack_networking_network_v2.swarm.name}"
    python_bin        = "/usr/bin/python3"
    swarm_labels      = "worker,gitlab,prometheus"

  }

  network {
    name              = "${openstack_networking_network_v2.swarm.name}"
  }
}

# Assign floating ip to the swarm workers for external connectivity.
resource "openstack_compute_floatingip_associate_v2" "swarm_worker" {
  count = "${var.swarm_worker_count}"

  floating_ip = "${element(openstack_networking_floatingip_v2.swarm_worker.*.address, count.index)}"
  instance_id = "${element(openstack_compute_instance_v2.swarm_worker.*.id, count.index)}"
}

