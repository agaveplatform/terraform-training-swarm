output "swarm_leader_fips" {
  description = "The floating ip address of the swarm leader"
  value = "${var.wildcard_floating_ip_address}"
}

output "swarm_manager_fips" {
  description = "An array of the floating ip addresses of the swarm masters"
  value = ["${openstack_networking_floatingip_v2.swarm_manager.*.address}"]
}

output "swarm_worker_fips" {
  description = "An array of the floating ip addresses of the swarm workers"
  value = "${openstack_networking_floatingip_v2.swarm_worker.*.address}"
}

output "training_node_fips" {
  description = "An array of the floating ip addresses of the training nodes"
  value = "${openstack_networking_floatingip_v2.swarm_training.*.address}"
}
