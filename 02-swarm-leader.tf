resource "openstack_compute_floatingip_associate_v2" "swarm_manager" {
  #floating_ip = "${openstack_compute_floatingip_associate_v2.swarm_manager.floating_ip}"
  floating_ip = "149.165.157.242"
  instance_id = "${openstack_compute_instance_v2.swarm_manager.id}"
}

resource "openstack_compute_instance_v2" "swarm_manager" {
  name            = "swarm-manager-0"
  count           = 1

  image_id        = "${var.openstack_images["ubuntu1604"]}"

  flavor_id       = "${var.openstack_flavor["m1_medium"]}"
  key_pair        = "${openstack_compute_keypair_v2.keypair.name}"
  security_groups = ["${openstack_compute_secgroup_v2.swarm_tf_secgroup_1.name}"]

  network {
    name          = "${openstack_networking_network_v2.swarm_tf_network1.name}"
  }
}

resource "null_resource" "swarm_manager_configure_auth" {

  # copies ssh private key to the swarm master. This key should match
  # openstack_compute_keypair_v2.keypair private key
  provisioner "file" {
    content      = "${file(var.openstack_keypair_private_key_path)}"
    destination = "/home/agaveops/.ssh/key.pem"
    connection {
      host = "${openstack_compute_floatingip_associate_v2.swarm_manager.floating_ip}"
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
      host = "${openstack_compute_floatingip_associate_v2.swarm_manager.floating_ip}"
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
      host = "${openstack_compute_floatingip_associate_v2.swarm_manager.floating_ip}"
      user = "agaveops"
      private_key = "${file(var.openstack_keypair_private_key_path)}"
      timeout = "90s"
    }
  }
}

resource "null_resource" "swarm_manager_init_swarm" {

  # Initialize the swarm master and configure ssh access between this host and
  # the rest of the swarm via a service account.
  provisioner "remote-exec" {
    inline = [
      "docker swarm init",
      "docker network create --driver overlay --subnet=10.0.9.0/24 ${var.swarm_overlay_network_name}",
      "docker swarm join-token --quiet worker > /home/agaveops/worker-token",
      "docker swarm join-token --quiet manager > /home/agaveops/manager-token",
      "docker node update --label-add 'node.labels.environment=training' ${openstack_compute_instance_v2.swarm_manager.name}",
    ]
    connection {
      host = "${openstack_compute_floatingip_associate_v2.swarm_manager.floating_ip}"
      user = "agaveops"
      private_key = "${file(var.openstack_keypair_private_key_path)}"
      timeout = "90s"
    }
  }
}

resource "null_resource" "swarm_manager_deploy_monitoring_stack" {
  depends_on = ["null_resource.swarm_manager_init_swarm"]

  # copies resolved host monitoring compose file to the slave
  provisioner "file" {
    content      = "${template_file.swarm_monitoring_stack_template.resolved}"
    destination = "/home/agaveops/monitoring.stack.yml"
    connection {
      host = "${openstack_compute_floatingip_associate_v2.swarm_manager.floating_ip}"
      user = "agaveops"
      private_key = "${file(var.openstack_keypair_private_key_path)}"
      timeout = "90s"
    }
  }

  # launch the host monitoring docker containers by invoking docker compose
  # with the monitoring compose file.
  provisioner "remote-exec" {
    inline = [
      "docker stack deploy -c monitoring.stack.yml monitoring",
    ]
    connection {
      host = "${openstack_compute_floatingip_associate_v2.swarm_manager.floating_ip}"
      user = "agaveops"
      private_key = "${file(var.openstack_keypair_private_key_path)}"
      timeout = "90s"
    }
  }
}

resource "null_resource" "swarm_master_init_host_monitors" {
  depends_on = ["null_resource.swarm_manager_deploy_monitoring_stack"]

  # copies resolved host monitoring compose file to the slave
  provisioner "file" {
    content      = "${template_file.swarm_host_monitors_template.resolved}"
    destination = "/home/agaveops/monitors.compose.yml"
    connection {
      host = "${openstack_compute_floatingip_associate_v2.swarm_manager.floating_ip}"
      user = "agaveops"
      private_key = "${file(var.openstack_keypair_private_key_path)}"
      timeout = "90s"
    }
  }

  # launch the host monitoring docker containers by invoking docker compose
  # with the monitoring compose file.
  provisioner "remote-exec" {
    inline = [
      "docker-compose -f monitors.compose.yml up -d",
    ]
    connection {
      host = "${openstack_compute_floatingip_associate_v2.swarm_manager.floating_ip}"
      user = "agaveops"
      private_key = "${file(var.openstack_keypair_private_key_path)}"
      timeout = "90s"
    }
  }
}

resource "null_resource" "swarm_manager_deploy_training_stack" {
  depends_on = ["openstack_compute_floatingip_associate_v2.swarm_manager"]

  # copies compose file with network stack to the swarm master
  provisioner "file" {
    source      = "templates/monitoring"
    destination = "/home/agaveops/monitoring"
    connection {
      host = "${openstack_compute_floatingip_associate_v2.swarm_manager.floating_ip}"
      user = "agaveops"
      private_key = "${file(var.openstack_keypair_private_key_path)}"
      timeout = "90s"
    }
  }

  # copies compose file with network stack to the swarm master
  provisioner "file" {
    source      = "templates/traefik"
    destination = "/home/agaveops/traefik"
    connection {
      host = "${openstack_compute_floatingip_associate_v2.swarm_manager.floating_ip}"
      user = "agaveops"
      private_key = "${file(var.openstack_keypair_private_key_path)}"
      timeout = "90s"
    }
  }

  # copies compose file with network stack to the swarm master
  provisioner "file" {
    source      = "templates/training"
    destination = "/home/agaveops/training"
    connection {
      host = "${openstack_compute_floatingip_associate_v2.swarm_manager.floating_ip}"
      user = "agaveops"
      private_key = "${file(var.openstack_keypair_private_key_path)}"
      timeout = "90s"
    }
  }


}
