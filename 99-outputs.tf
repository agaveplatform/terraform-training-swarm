output "swarm_master" {
  description = "The floating ip address of the swarm leader"
  value = "${openstack_compute_floatingip_associate_v2.swarm_manager.floating_ip}"
}

output "swarm_managers" {
  description = "An array of the floating ip addresses of the swarm masters"
  value = "${concat(list(openstack_compute_floatingip_associate_v2.swarm_manager.floating_ip),openstack_networking_floatingip_v2.swarm_tf_floatip_managerx.*.address)}"
}

output "swarm_slaves" {
  description = "An array of the floating ip addresses of the swarm slaves"
  value = "${openstack_networking_floatingip_v2.swarm_tf_floatip_slave.*.address}"
}

output "training_nodes" {
  description = "An array of the floating ip addresses of the training nodes"
  value = "${openstack_networking_floatingip_v2.swarm_tf_floatip_training.*.address}"
}

output "etc_hosts" {
  description = "A valid /etc/hosts entry for all hosts"
  value = "${join("\n",list(join("\n", formatlist("%s %s",openstack_compute_floatingip_associate_v2.swarm_manager.floating_ip, openstack_compute_instance_v2.swarm_manager.*.name)),join("\n", formatlist("%s %s",openstack_networking_floatingip_v2.swarm_tf_floatip_managerx.*.address, openstack_compute_instance_v2.swarm_managerx.*.name)),join("\n", formatlist("%s %s",openstack_networking_floatingip_v2.swarm_tf_floatip_slave.*.address, openstack_compute_instance_v2.swarm_slave.*.name)),join("\n", formatlist("%s %s",openstack_networking_floatingip_v2.swarm_tf_floatip_training.*.address, openstack_compute_instance_v2.training_node.*.name))))}"
}

output "attendee_hosts" {
  description = "A printout of the attendee username and their host ip"
  value = "${join("\n",list(formatlist("%s %s",var.attendees, openstack_networking_floatingip_v2.swarm_tf_floatip_training.*.address)))}"
}

output "started_at" {
  description = "Time when the plan started running"
  value = "${timestamp()}"
}

output "ended_at" {
  depends_on = ["null_resource.training_deploy_jupyter_stack"]
  description = "Time when the plan completed running"
  value = "${timestamp()}"
}
