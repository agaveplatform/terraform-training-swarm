# Provision the swarm managerx node(s)
resource "openstack_compute_instance_v2" "swarm_managerx" {
  depends_on      = ["openstack_compute_instance_v2.swarm_manager"]
  name            = "swarm-manager-${count.index+1}"
  count           = "${var.swarm_manager_count - 1}"

  image_id        = "${var.openstack_images["ubuntu1604"]}"

  flavor_id       = "${var.openstack_flavor["m1_small"]}"
  key_pair        = "${openstack_compute_keypair_v2.keypair.name}"
  security_groups = ["${openstack_compute_secgroup_v2.swarm_tf_secgroup_1.name}"]

  #user_data       =  "${data.template_file.managerinit.rendered}"

  network {
    name          = "${openstack_networking_network_v2.swarm_tf_network1.name}"
  }
}

# Assign floating ip to the swarm managers for external connectivity
resource "openstack_compute_floatingip_associate_v2" "swarm_managerx" {
  count = "${var.swarm_manager_count - 1}"

  floating_ip = "${element(openstack_networking_floatingip_v2.swarm_tf_floatip_managerx.*.address, count.index)}"
  instance_id = "${element(openstack_compute_instance_v2.swarm_managerx.*.id, count.index)}"
}

# Configure auth login for the ops user account to be used for node to node
# communication within the swarm
resource "null_resource" "swarm_managerx_configure_auth" {
  depends_on = ["openstack_compute_floatingip_associate_v2.swarm_slave"]
  count = "${var.swarm_manager_count - 1}"

  # copies ssh private key to the swarm master. This key should match
  # openstack_compute_keypair_v2.keypair private key
  provisioner "file" {
    content      = "${file(var.openstack_keypair_private_key_path)}"
    destination = "/home/agaveops/.ssh/key.pem"
    connection {
      host = "${element(openstack_networking_floatingip_v2.swarm_tf_floatip_managerx.*.address, count.index)}"
      user = "agaveops"
      private_key = "${file(var.openstack_keypair_private_key_path)}"
      timeout = "90s"
    }
  }

  # copies ssh public key to the swarm master. This key should match
  # openstack_compute_keypair_v2.keypair public key
  provisioner "file" {
    content      = "${file(var.openstack_keypair_public_key_path)}"
    destination = "/home/agaveops/.ssh/key.pub"
    connection {
      host = "${element(openstack_networking_floatingip_v2.swarm_tf_floatip_managerx.*.address, count.index)}"
      user = "agaveops"
      private_key = "${file(var.openstack_keypair_private_key_path)}"
      timeout = "90s"
    }
  }

  # Initialize the swarm master and configure ssh access between this host and
  # the rest of the swarm via a service account.
  provisioner "remote-exec" {

    inline = [
      "cat /home/agaveops/.ssh/key.pub >> /home/agaveops/.ssh/authorized_keys",
      "chmod 600 /home/agaveops/.ssh/key.pem",
      "chmod 644 /home/agaveops/.ssh/key.pub",
      "chown -R agaveops /home/agaveops/.ssh"
    ]
    connection {
      host = "${element(openstack_networking_floatingip_v2.swarm_tf_floatip_managerx.*.address, count.index)}"
      user = "agaveops"
      private_key = "${file(var.openstack_keypair_private_key_path)}"
      timeout = "90s"
    }
  }
}

# Join the swarm as a manager
resource "null_resource" "swarm_managerx_join_cluster" {
  depends_on = ["null_resource.swarm_manager_configure_auth"]
  count = "${var.swarm_manager_count - 1}"

  # Add the managerx node to the swarm as a master. Apply appropraite labels.
  provisioner "remote-exec" {
    inline = [
      "scp -o StrictHostKeyChecking=no -o NoHostAuthenticationForLocalhost=yes -o UserKnownHostsFile=/dev/null -i /home/agaveops/.ssh/key.pem agaveops@${openstack_compute_floatingip_associate_v2.swarm_manager.floating_ip}:/home/agaveops/worker-token /home/agaveops/worker-token",
      "echo 'docker swarm join --token $(cat /home/agaveops/manager-token) ${openstack_compute_instance_v2.swarm_manager.access_ip_v4}'",
      "docker swarm join --token $(cat /home/agaveops/manager-token) ${openstack_compute_instance_v2.swarm_manager.access_ip_v4}"
    ]
    connection {
      host = "${element(openstack_networking_floatingip_v2.swarm_tf_floatip_managerx.*.address, count.index)}"
      user = "agaveops"
      private_key = "${file(var.openstack_keypair_private_key_path)}"
      timeout = "90s"
    }
  }

  # Add appropraite labels to this swarm master
  provisioner "remote-exec" {
    inline = [
      "docker node update --label-add 'environment=training' ${element(openstack_compute_instance_v2.swarm_managerx.*.name, count.index)}",
    ]
    connection {
      host = "${element(openstack_networking_floatingip_v2.swarm_tf_floatip_managerx.*.address, count.index)}"
      user = "agaveops"
      private_key = "${file(var.openstack_keypair_private_key_path)}"
      timeout = "90s"
    }
  }
}
