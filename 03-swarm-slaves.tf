# Provision the swarm worker node(s)
resource "openstack_compute_instance_v2" "swarm_slave" {
  depends_on      = ["openstack_compute_instance_v2.swarm_managerx"]
  name            = "swarm-slave-${count.index}"
  count           = "${var.swarm_slave_count}"

  image_id        = "${var.openstack_images["ubuntu1604"]}"

  flavor_id       = "${var.openstack_flavor["m1_medium"]}"
  key_pair        = "${openstack_compute_keypair_v2.keypair.name}"
  security_groups = ["${openstack_compute_secgroup_v2.swarm_tf_secgroup_1.name}"]

  #user_data       = "${data.template_file.slaveinit.rendered}"

  network {
    name          = "${openstack_networking_network_v2.swarm_tf_network1.name}"
  }
}

# Assign floating ip to the swarm slaves for external connectivity.
resource "openstack_compute_floatingip_associate_v2" "swarm_slave" {
  count = "${var.swarm_slave_count}"
  floating_ip = "${element(openstack_networking_floatingip_v2.swarm_tf_floatip_slave.*.address, count.index)}"
  instance_id = "${element(openstack_compute_instance_v2.swarm_slave.*.id, count.index)}"
}

resource "null_resource" "swarm_slave_configure_auth" {
  depends_on = ["null_resource.swarm_manager_init_swarm"]
  count = "${var.swarm_slave_count}"

  # copies ssh private key to the swarm master. This key should match
  # openstack_compute_keypair_v2.keypair private key
  provisioner "file" {
    content      = "${file(var.openstack_keypair_private_key_path)}"
    destination = "/home/agaveops/.ssh/key.pem"
    connection {
      host = "${element(openstack_networking_floatingip_v2.swarm_tf_floatip_slave.*.address, count.index)}"
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
      host = "${element(openstack_networking_floatingip_v2.swarm_tf_floatip_slave.*.address, count.index)}"
      user = "agaveops"
      private_key = "${file(var.openstack_keypair_private_key_path)}"
      timeout = "90s"
    }
  }

  # Initialize the swarm master and configure ssh access between this host and
  # the rest of the swarm via a service account.
  provisioner "remote-exec" {
    inline = [
      "chmod 600 /home/agaveops/.ssh/key.pem",
      "chmod 644 /home/agaveops/.ssh/key.pub",
      "cat /home/agaveops/.ssh/key.pub >> /home/agaveops/.ssh/authorized_keys",
      "chown -R agaveops:agaveops /home/agaveops/.ssh"
    ]
    connection {
      host = "${element(openstack_networking_floatingip_v2.swarm_tf_floatip_slave.*.address, count.index)}"
      user = "agaveops"
      private_key = "${file(var.openstack_keypair_private_key_path)}"
      timeout = "90s"
    }
  }
}

# Join the swarm as a worker.
resource "null_resource" "swarm_slave_join_cluster" {
  depends_on = ["null_resource.swarm_slave_configure_auth"]
  count = "${var.swarm_slave_count}"

  # Connect to the slave node and join the host to the swarm as a worker node
  provisioner "remote-exec" {
    inline = [
      "scp -o StrictHostKeyChecking=no -o NoHostAuthenticationForLocalhost=yes -o UserKnownHostsFile=/dev/null -i /home/agaveops/.ssh/key.pem agaveops@${openstack_compute_floatingip_associate_v2.swarm_manager.floating_ip}:/home/agaveops/worker-token /home/agaveops/worker-token",
      "docker swarm leave || true",
      "echo 'swarm join --token '$(cat /home/agaveops/worker-token)' ${openstack_compute_instance_v2.swarm_manager.access_ip_v4}:2377'",
      "docker swarm join --token $(cat /home/agaveops/worker-token) ${openstack_compute_instance_v2.swarm_manager.access_ip_v4}:2377 || true"
    ]
    connection {
      host = "${element(openstack_networking_floatingip_v2.swarm_tf_floatip_slave.*.address, count.index)}"
      user = "agaveops"
      private_key = "${file(var.openstack_keypair_private_key_path)}"
      timeout = "90s"
    }
  }

  # Connect to the swarm manager and assign relevant labels to the slave node
  provisioner "remote-exec" {
    inline = [
      "echo 'docker node update --label-add environment=swarm --label-add slave=yes ${element(openstack_compute_instance_v2.swarm_slave.*.name, count.index)}'",
      "docker node update --label-add 'environment=swarm' --label-add 'slave=yes' ${element(openstack_compute_instance_v2.swarm_slave.*.name, count.index)}"
    ]
    connection {
      host = "${openstack_compute_floatingip_associate_v2.swarm_manager.floating_ip}"
      user = "agaveops"
      private_key = "${file(var.openstack_keypair_private_key_path)}"
      timeout = "90s"
    }
  }
}
