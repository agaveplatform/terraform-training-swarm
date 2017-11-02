# Provision the swarm leader node
resource "openstack_compute_instance_v2" "swarm_manager" {
  name            = "swarm-manager-0"
  count           = 1

  image_id        = "${var.openstack_images["ubuntu1604"]}"
  availability_zone = "${var.openstack_availability_zone}"
  flavor_id       = "${var.openstack_flavor["m2_medium"]}"
  key_pair        = "${openstack_compute_keypair_v2.keypair.name}"
  security_groups = ["${openstack_compute_secgroup_v2.swarm_tf_secgroup_1.name}"]

  network {
    name          = "${var.openstack_network_name}"
  }
}

resource "null_resource" "swarm_manager_configure_auth" {

  # copies ssh private key to the swarm master. This key should match
  # openstack_compute_keypair_v2.keypair private key
  provisioner "file" {
    content      = "${file(var.openstack_keypair_private_key_path)}"
    destination = "/home/agaveops/.ssh/key.pem"
    connection {
      host = "${openstack_compute_instance_v2.swarm_manager.access_ip_v4}"
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
      host = "${openstack_compute_instance_v2.swarm_manager.access_ip_v4}"
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
      host = "${openstack_compute_instance_v2.swarm_manager.access_ip_v4}"
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
      host = "${openstack_compute_instance_v2.swarm_manager.access_ip_v4}"
      user = "agaveops"
      private_key = "${file(var.openstack_keypair_private_key_path)}"
      timeout = "90s"
    }
  }
}
