resource "null_resource" "ansible_inventory" {
  depends_on = ["null_resource.swarm_manager_init_swarm", "null_resource.swarm_managerx_join_cluster", "null_resource.swarm_slave_join_cluster", "null_resource.training_deploy_jupyter_stack"]

  provisioner "local-exec" {
    command = "echo \"[swarm-manager]\" > ansible/${var.swarm_environment}"
  }

  provisioner "local-exec" {
    command = "echo \"${format("%s %s ansible_ssh_user=%s", openstack_compute_instance_v2.swarm_manager.name, openstack_compute_instance_v2.swarm_manager.access_ip_v4, var.ssh_user)}\" >> ansible/${var.swarm_environment}"
  }
}

resource "null_resource" "ansible_inventory_managers" {
  depends_on = ["null_resource.ansible_inventory"]
  count = "${var.swarm_manager_count - 1}"

  provisioner "local-exec" {
    command = "echo \"${format("%s %s ansible_ssh_user=%s", element(openstack_compute_instance_v2.swarm_managerx.*.name, count.index), element(openstack_compute_instance_v2.swarm_managerx.*.access_ip_v4, count.index), var.ssh_user)}\" >> ansible/${var.swarm_environment}"
  }

}

resource "null_resource" "ansible_inventory_slave_header" {
  depends_on = ["null_resource.ansible_inventory_managers"]
  provisioner "local-exec" {
    command = "echo \"\" >> ansible/${var.swarm_environment}"
  }

  provisioner "local-exec" {
    command = "echo \"[swarm-slave]\" >> ansible/${var.swarm_environment}"
  }
}

resource "null_resource" "ansible_inventory_slaves" {
  depends_on = ["null_resource.ansible_inventory_slave_header"]
  count = "${var.swarm_slave_count}"

  provisioner "local-exec" {
    command = "echo \"${format("%s %s ansible_ssh_user=%s", element(openstack_compute_instance_v2.swarm_slave.*.name, count.index), element(openstack_compute_instance_v2.swarm_slave.*.access_ip_v4, count.index), var.ssh_user)}\" >> ansible/${var.swarm_environment}"
  }
}

resource "null_resource" "ansible_inventory_training_header" {
  depends_on = ["null_resource.ansible_inventory_slaves"]

  provisioner "local-exec" {
    command = "echo \"\" >> ansible/${var.swarm_environment}"
  }

  provisioner "local-exec" {
    command = "echo \"[training-node:attendee]\" >> ansible/${var.swarm_environment}"
  }
}

resource "null_resource" "ansible_inventory_training" {
  depends_on = ["null_resource.ansible_inventory_training_header"]
  count = "${var.swarm_slave_count}"

  provisioner "local-exec" {
    command = "echo \"${format("%s %s ansible_ssh_user=%s", element(openstack_compute_instance_v2.training_node.*.name, count.index), element(openstack_compute_instance_v2.training_node.*.access_ip_v4, count.index), var.ssh_user)}\" >> ansible/${var.swarm_environment}"
  }
}

resource "null_resource" "ansible_inventory_groups" {
  depends_on = ["null_resource.ansible_inventory_training"]
  count = "${length(var.attendees)}"

  provisioner "local-exec" {
    command = "echo \"\" >> ansible/${var.swarm_environment}"
  }

  provisioner "local-exec" {
    command = "echo \"[attendee-${var.attendees[count.index]}]\" >> ansible/${var.swarm_environment}"
  }

  provisioner "local-exec" {
    command = "echo \"${element(openstack_compute_instance_v2.training_node.*.name, count.index)} swarm_labels=${element(openstack_compute_instance_v2.training_node.*.name, count.index)},sandbox,jupyter\" >> ansible/${var.swarm_environment}"
  }
}

resource "null_resource" "ansible_training_group_vars" {
  depends_on = ["null_resource.ansible_inventory_groups"]
  count = "${length(var.attendees)}"

  provisioner "local-exec" {
    command = "echo \"---\" > ansible/group_vars/attendee-${var.attendees[count.index]}"
  }

  provisioner "local-exec" {
    command = "echo \"# file: group_vars/${var.attendees[count.index]}-swarm-host\" >> ansible/group_vars/attendee-${var.attendees[count.index]}"
  }

  provisioner "local-exec" {
    command = "echo \"username: ${var.attendees[count.index]}\" >> ansible/group_vars/attendee-${var.attendees[count.index]}"
  }
}


resource "null_resource" "ansible_group_vars" {
  depends_on = ["null_resource.ansible_training_group_vars"]

  provisioner "local-exec" {
    command = "echo \"training_attendees: [${join(",", var.attendees)}]\" > ansible/group_vars/all"
  }
}
