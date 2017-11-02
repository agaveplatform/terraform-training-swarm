# Provision the training node(s)
resource "openstack_compute_instance_v2" "training_node" {
  name            = "training-node-${var.attendees[count.index]}"
  count           = "${length(var.attendees)}"

  image_id        = "${var.openstack_images["ubuntu1604"]}"
  availability_zone = "${var.openstack_availability_zone}"
  flavor_id       = "${var.openstack_flavor["m2_medium"]}"
  key_pair        = "${openstack_compute_keypair_v2.keypair.name}"
  security_groups = ["${openstack_compute_secgroup_v2.swarm_tf_secgroup_1.name}"]

  #user_data       = "${data.template_file.traininginit.rendered}"

  network {
    name          = "${var.openstack_network_name}"
  }
}

resource "null_resource" "training_node_auth_config" {
  depends_on = ["null_resource.swarm_manager_init_swarm"]
  count = "${length(var.attendees)}"

  # copies ssh private key to the swarm master. This key should match
  # openstack_compute_keypair_v2.keypair private key
  provisioner "file" {
    content      = "${file(var.openstack_keypair_private_key_path)}"
    destination = "/home/agaveops/.ssh/key.pem"
    connection {
      host = "${element(openstack_compute_instance_v2.training_node.*.access_ip_v4, count.index)}"
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
      host = "${element(openstack_compute_instance_v2.training_node.*.access_ip_v4, count.index)}"
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
      host = "${element(openstack_compute_instance_v2.training_node.*.access_ip_v4, count.index)}"
      user = "agaveops"
      private_key = "${file(var.openstack_keypair_private_key_path)}"
      timeout = "90s"
    }
  }
}

# Join the swarm as a worker
resource "null_resource" "training_node_join_cluster" {
  depends_on = ["null_resource.training_node_auth_config"]
  count = "${length(var.attendees)}"

  # Stop all containers and leave the swarm
  provisioner "remote-exec" {
    inline = [
      "[ -z \"$(docker ps -a -q)\" ] && docker stop $(docker ps -a -q) || true",
      "[ -z \"$(docker ps -a -q)\" ] && docker rm $(docker ps -a -q) || true",
      "docker swarm leave || true"
    ]
    connection {
      host = "${element(openstack_compute_instance_v2.training_node.*.access_ip_v4, count.index)}"
      user = "agaveops"
      private_key = "${file(var.openstack_keypair_private_key_path)}"
      timeout = "90s"
    }
  }

  # Remove the node from the swarm on the master side
  provisioner "remote-exec" {
    inline = [
      "sleep 10",
      "docker node rm ${element(openstack_compute_instance_v2.training_node.*.name, count.index)} || true",
    ]
    connection {
      host = "${openstack_compute_instance_v2.swarm_manager.access_ip_v4}"
      user = "agaveops"
      private_key = "${file(var.openstack_keypair_private_key_path)}"
      timeout = "90s"
    }
  }

  # # Install rex-ray plugin
  # provisioner "remote-exec" {
  #   when = "create"
  #   inline = [
  #     "docker plugin install rexray/cinder CINDER_AUTHURL=${var.openstack_auth_url} CINDER_USERNAME=${var.openstack_username} CINDER_PASSWORD=${var.openstack_password} CINDER_TENANTNAME=${var.openstack_project_name} CINDER_DOMAINNAME=${var.openstack_tenant_name}",
  #   ]
  #   connection {
  #     host = "${element(openstack_compute_instance_v2.training_node.*.access_ip_v4, count.index)}"
  #     user = "agaveops"
  #     private_key = "${file(var.openstack_keypair_private_key_path)}"
  #     timeout = "90s"
  #   }
  # }

  # Initialize the swarm master and configure ssh access between this host and
  # the rest of the swarm via a service account.
  provisioner "remote-exec" {
    when = "create"
    inline = [
      "scp -o StrictHostKeyChecking=no -o NoHostAuthenticationForLocalhost=yes -o UserKnownHostsFile=/dev/null -i /home/agaveops/.ssh/key.pem agaveops@${openstack_compute_instance_v2.swarm_manager.access_ip_v4}:/home/agaveops/worker-token /home/agaveops/worker-token",
      "echo 'swarm join --token '$(cat /home/agaveops/worker-token)' ${openstack_compute_instance_v2.swarm_manager.access_ip_v4}:2377'",
      "docker swarm join --token $(cat /home/agaveops/worker-token) ${openstack_compute_instance_v2.swarm_manager.access_ip_v4}:2377 || true",
    ]
    connection {
      host = "${element(openstack_compute_instance_v2.training_node.*.access_ip_v4, count.index)}"
      user = "agaveops"
      private_key = "${file(var.openstack_keypair_private_key_path)}"
      timeout = "90s"
    }
  }

  # Connect to the swarm manager and assign relevant labels to the training node
  provisioner "remote-exec" {
    inline = [
      "echo 'docker node update --role=worker --label-add environment=training --label-add training.name=${var.training_event} --label-add training.user=${var.attendees[count.index]}  ${element(openstack_compute_instance_v2.training_node.*.name, count.index)}'",
      "docker node update --role=worker --label-add 'environment=training' --label-add 'training.name=${var.training_event}' --label-add 'training.user=${var.attendees[count.index]}' ${element(openstack_compute_instance_v2.training_node.*.name, count.index)} || true"
    ]
    connection {
      host = "${openstack_compute_instance_v2.swarm_manager.access_ip_v4}"
      user = "agaveops"
      private_key = "${file(var.openstack_keypair_private_key_path)}"
      timeout = "90s"
    }
  }
}
