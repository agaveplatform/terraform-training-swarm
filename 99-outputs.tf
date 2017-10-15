output "swarm_master" {
  value = "${openstack_compute_floatingip_associate_v2.swarm_manager.floating_ip}"
}

output "swarm_managers" {
  value = "${concat(list(openstack_compute_floatingip_associate_v2.swarm_manager.floating_ip),openstack_networking_floatingip_v2.swarm_tf_floatip_managerx.*.address)}"
}

output "swarm_slaves" {
  value = "${openstack_networking_floatingip_v2.swarm_tf_floatip_slave.*.address}"
}

output "training_nodes" {
  value = "${openstack_networking_floatingip_v2.swarm_tf_floatip_training.*.address}"
}

output "etc_hosts" {
  value = "${join("\n",list(join("\n", formatlist("%s %s",openstack_compute_floatingip_associate_v2.swarm_manager.floating_ip, openstack_compute_instance_v2.swarm_manager.*.name)),join("\n", formatlist("%s %s",openstack_networking_floatingip_v2.swarm_tf_floatip_managerx.*.address, openstack_compute_instance_v2.swarm_managerx.*.name)),join("\n", formatlist("%s %s",openstack_networking_floatingip_v2.swarm_tf_floatip_slave.*.address, openstack_compute_instance_v2.swarm_slave.*.name)),join("\n", formatlist("%s %s",openstack_networking_floatingip_v2.swarm_tf_floatip_training.*.address, openstack_compute_instance_v2.training_node.*.name))))}"
}
