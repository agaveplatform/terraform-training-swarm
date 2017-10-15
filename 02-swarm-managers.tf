data "template_file" "managerinit" {
    template = "${file("managerinit.sh")}"
    vars {
        swarm_manager = "${openstack_compute_floatingip_associate_v2.swarm_manager.floating_ip}"
    }
}

resource "openstack_compute_floatingip_associate_v2" "swarm_manager" {
  #floating_ip = "${openstack_compute_floatingip_associate_v2.swarm_manager.floating_ip}"
  floating_ip = "149.165.157.242"
  instance_id = "${openstack_compute_instance_v2.swarm_manager.id}"
}

resource "null_resource" "init_swarm_manager" {
  depends_on = ["openstack_compute_floatingip_associate_v2.swarm_manager"]

  # copies compose file with network stack to the swarm master
  provisioner "file" {
    source      = "docker-compose.yml"
    destination = "/home/agaveops/docker-compose.yml"
    connection {
      host = "${openstack_compute_floatingip_associate_v2.swarm_manager.floating_ip}"
      user = "agaveops"
      private_key = "${file(var.openstack_keypair_private_key_path)}"
      timeout = "90s"
    }
  }

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
}

resource "null_resource" "init_swarm_manager_auth" {
  depends_on = ["null_resource.init_swarm_manager"]

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
  depends_on = ["null_resource.init_swarm_manager_auth"]

  # Initialize the swarm master and configure ssh access between this host and
  # the rest of the swarm via a service account.
  provisioner "remote-exec" {
    inline = [
      "docker swarm init",
      "docker network create --driver overlay --subnet=10.0.9.0/24 ${var.swarm_overlay_network_name}",
      "docker swarm join-token --quiet worker > /home/agaveops/worker-token",
      "docker swarm join-token --quiet manager > /home/agaveops/manager-token",
      "docker node update --label-add 'node.labels.environment=training' ${openstack_compute_instance_v2.swarm_manager.name}",
      "docker stack deploy --compose-file /home/agaveops/docker-stack.monitoring.yml monitoring > /dev/null",
      "ELASTICSEARCH_HOSTNAME=${openstack_compute_floatingip_associate_v2.swarm_manager.floating_ip} LOGSTACHE_HOSTNAME=${openstack_compute_floatingip_associate_v2.swarm_manager.floating_ip} docker-compose -f monitors.yml up -d ",
    ]
    connection {
      host = "${openstack_compute_floatingip_associate_v2.swarm_manager.floating_ip}"
      user = "agaveops"
      private_key = "${file(var.openstack_keypair_private_key_path)}"
      timeout = "90s"
    }
  }
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

resource "openstack_compute_floatingip_associate_v2" "swarm_managerx" {
  count = "${var.swarm_manager_count - 1}"

  floating_ip = "${element(openstack_networking_floatingip_v2.swarm_tf_floatip_managerx.*.address, count.index)}"
  instance_id = "${element(openstack_compute_instance_v2.swarm_managerx.*.id, count.index)}"
}

resource "null_resource" "init_swarm_managerx" {
  depends_on = ["openstack_compute_floatingip_associate_v2.swarm_slave"]
  count = "${var.swarm_manager_count - 1}"

  # copies compose file with network stack to the swarm master
  provisioner "file" {
    source      = "docker-compose.yml"
    destination = "/home/agaveops/docker-compose.yml"
    connection {
      host = "${element(openstack_networking_floatingip_v2.swarm_tf_floatip_managerx.*.address, count.index)}"
      user = "agaveops"
      private_key = "${file(var.openstack_keypair_private_key_path)}"
      timeout = "90s"
    }
  }

  # copies traefik assets to proxy connections to services running in the swarm
  provisioner "file" {
    source      = "traefik"
    destination = "/home/agaveops/traefik"
    connection {
      host = "${element(openstack_networking_floatingip_v2.swarm_tf_floatip_managerx.*.address, count.index)}"
      user = "agaveops"
      private_key = "${file(var.openstack_keypair_private_key_path)}"
      timeout = "90s"
    }
  }

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
}

resource "null_resource" "init_swarm_managerx_auth" {
  depends_on = ["null_resource.init_swarm_managerx"]
  count = "${var.swarm_manager_count - 1}"

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

resource "null_resource" "join_swarm_managerx_to_cluster" {
  depends_on = ["null_resource.init_swarm_managerx_auth"]
  count = "${var.swarm_manager_count - 1}"

  # Initialize the swarm master and configure ssh access between this host and
  # the rest of the swarm via a service account.
  provisioner "remote-exec" {
    inline = [
      "scp -o StrictHostKeyChecking=no -o NoHostAuthenticationForLocalhost=yes -o UserKnownHostsFile=/dev/null -i /home/agaveops/.ssh/key.pem agaveops@${openstack_compute_floatingip_associate_v2.swarm_manager.floating_ip}:/home/agaveops/worker-token /home/agaveops/worker-token",
      "echo 'docker swarm join --token $(cat /home/agaveops/manager-token) ${openstack_compute_instance_v2.swarm_manager.access_ip_v4}'",
      "docker swarm join --token $(cat /home/agaveops/manager-token) ${openstack_compute_instance_v2.swarm_manager.access_ip_v4}",
      "docker node update --label-add 'environment=training' ${element(openstack_compute_instance_v2.swarm_managerx.*.name, count.index)}",
      "ELASTICSEARCH_HOSTNAME=${openstack_compute_floatingip_associate_v2.swarm_manager.floating_ip} LOGSTACHE_HOSTNAME=${openstack_compute_floatingip_associate_v2.swarm_manager.floating_ip} docker-compose up -d ",
    ]
    connection {
      host = "${element(openstack_networking_floatingip_v2.swarm_tf_floatip_managerx.*.address, count.index)}"
      user = "agaveops"
      private_key = "${file(var.openstack_keypair_private_key_path)}"
      timeout = "90s"
    }
  }
}

resource "openstack_compute_instance_v2" "swarm_managerx" {
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
