# Create a floating ip address for the swarm manager nodes
resource "openstack_networking_floatingip_v2" "swarm_manager" {
  pool = "public"
  count = "${var.swarm_manager_count - 1}"
}

# Create a floating ip address for the swarm slave nodes
resource "openstack_networking_floatingip_v2" "swarm_worker" {
  pool = "public"
  count = "${length(var.swarm_worker_count)}"
}

# Create a floating ip address for the training nodes
resource "openstack_networking_floatingip_v2" "swarm_training" {
  pool = "public"
  count = "${length(var.attendees)}"
}
