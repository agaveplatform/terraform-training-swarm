# Provision the swarm leader node
resource "openstack_compute_instance_v2" "swarm_manager" {
  name            = "swarm-manager-0"
  count           = 1

  image_id        = "${var.openstack_images["ubuntu1604"]}"

  flavor_id       = "${var.openstack_flavor["m1_small"]}"
  key_pair        = "${openstack_compute_keypair_v2.keypair.name}"
  security_groups = ["${openstack_compute_secgroup_v2.swarm_tf_secgroup_1.name}"]

  metadata = {
    ssh_user         = "agaveops"
    extra_groups     = "manager_nodes,leader_node,swarm_manager,training_cluster,terraform,${var.training_event}"
    depends_on       = "${var.network_id}"
  }

  network {
    name          = "${openstack_networking_network_v2.swarm_tf_network1.name}"
  }
}

# Assign floating ip to the swarm leader for external connectivity
resource "openstack_compute_floatingip_associate_v2" "swarm_manager" {
  # uncomment to assign a new floating ip with each deployment
  #floating_ip = "${openstack_networking_floatingip_v2.swarm_tf_floatip_manager.address}"
  floating_ip = "149.165.156.120"
  instance_id = "${openstack_compute_instance_v2.swarm_manager.id}"
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
      timeout = "600s"
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

# Create the swarm and establish leadership
resource "null_resource" "swarm_manager_init_swarm" {

  # Initialize the swarm, making this node the leader. Add appropriate labels
  provisioner "remote-exec" {
    inline = [
      "docker swarm init",
      "docker network create --driver overlay --attachable ${var.swarm_overlay_network_name}",
      "docker swarm join-token --quiet worker > /home/agaveops/worker-token",
      "docker swarm join-token --quiet manager > /home/agaveops/manager-token",
      "docker node update --label-add 'node.labels.environment=training' ${openstack_compute_instance_v2.swarm_manager.name}",
    ]
    connection {
      host = "${openstack_compute_floatingip_associate_v2.swarm_manager.floating_ip}"
      user = "agaveops"
      private_key = "${file(var.openstack_keypair_private_key_path)}"
      timeout = "600s"
    }
  }
}
