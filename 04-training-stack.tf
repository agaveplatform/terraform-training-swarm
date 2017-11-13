# The training sandbox is started as a Docker Compose service on each host
# due to the need for the privileged flag to bind-mount the docker socket
# to enabled container builds. The compose file joins the swarm overlay
# network so the sandbox container port is properly published and addressable
# via public dns externally and via the container service name from within
# each user's jupyter service container
# The user's data is mounted into a persistent volume on the training node
# and the data volume is bind-mounted into each container on a per-user basis.
# A NFS volume driver will be used in the future to persist the user's data
# in spite of node failure.
data "template_file" "training_sandbox_docker_compose_file" {
  template = "${file("templates/training/sandbox.compose.tpl")}"
  count    = "${length(var.attendees)}"

  vars {
      TRAINING_VM_HOSTNAME        = "${var.attendees[count.index]}-sandbox.${var.wildcard_domain_name}"
      TRAINING_SANDBOX_PORT       = "${var.sandbox_ssh_port}"
      TRAINING_USERNAME           = "${var.attendees[count.index]}"
      TRAINING_EVENT              = "${var.training_event}"
      TRAINING_VM_MACHINE         = "${element(openstack_compute_instance_v2.training_node.*.name, count.index)}"
      TRAINING_VM_ADDRESS         = "${element(openstack_networking_floatingip_v2.swarm_tf_floatip_training.*.address, count.index)}"
      SWARM_OVERLAY_NETWORK_NAME  = "${var.swarm_overlay_network_name}"
      TRAINING_SANBOX_IMAGE       = "${var.sandbox_image}"
      TRAINING_JUPYTER_IMAGE      = "${var.jupyter_image}"
  }
}

# The training sandbox is started as a Docker Compose service on each host
# due to the need for the privileged flag to bind-mount the docker socket
# to enabled container builds. The compose file joins the swarm overlay
# network so the sandbox container port is properly published and addressable
# via public dns externally and via the container service name from within
# each user's jupyter service container
# The user's data is mounted into a persistent volume on the training node
# and the data volume is bind-mounted into each container on a per-user basis.
# A NFS volume driver will be used in the future to persist the user's data
# in spite of node failure.
data "template_file" "training_sandbox_ssh_config_file" {
  template = "${file("templates/training/ssh_config.tpl")}"
  count    = "${length(var.attendees)}"

  vars {
      TRAINING_JENKINS_HOST  = "${var.attendees[count.index]}.${var.wildcard_domain_name}"
      TRAINING_SANDBOX_HOST  = "${var.attendees[count.index]}.${var.wildcard_domain_name}"
      TRAINING_SANDBOX_PORT  = "${var.sandbox_ssh_port}"
  }
}


# Copies training sandbox docker compose file to the training_node host and
# runs it to create the training sandbox for each attendee. Each sandbox
# is explicitly configured for the user. A local volume is created on the
# host and shared between the sandbox and jupyter service. This will
# survive container restarts, but be lost between host runs.
#
resource "null_resource" "training_sanbox_launch" {
  depends_on = ["null_resource.training_node_join_cluster"]
  count = "${length(var.attendees)}"

  # Remote to the training node and register the service. The compose file will ensure that
  # it is bound to run on this training node by mapping the node name into the constraints.
  provisioner "remote-exec" {
    inline = [
      "mkdir -p /home/agaveops/${var.attendees[count.index]}/ssh"
      "mkdir -p /home/agaveops/${var.attendees[count.index]}/sandbox"
      "mkdir -p /home/agaveops/${var.attendees[count.index]}/jupyter"
      "mkdir -p /home/agaveops/${var.attendees[count.index]}/jenkins"
      "mkdir -p /home/agaveops/${var.attendees[count.index]}/registry"
    ]
    connection {
      host = "${element(openstack_networking_floatingip_v2.swarm_tf_floatip_training.*.address, count.index)}"
      user = "agaveops"
      private_key = "${file(var.openstack_keypair_private_key_path)}"
      timeout = "90s"
    }
  }

  # copies compose file with network stack to the swarm master
  provisioner "file" {
    content       = "${element(data.template_file.training_sandbox_docker_compose_file.*.rendered, count.index)}"
    destination   = "/home/agaveops/sandbox.compose.${var.attendees[count.index]}.yml"
    connection {
      host = "${element(openstack_networking_floatingip_v2.swarm_tf_floatip_training.*.address, count.index)}"
      user = "agaveops"
      private_key = "${file(var.openstack_keypair_private_key_path)}"
      timeout = "90s"
    }
  }

  # copies compose file with network stack to the swarm master
  provisioner "file" {
    content       = "${element(data.template_file.training_sandbox_docker_compose_file.*.rendered, count.index)}"
    destination   = "/home/agaveops/sandbox.compose.${var.attendees[count.index]}.yml"
    connection {
      host = "${element(openstack_networking_floatingip_v2.swarm_tf_floatip_training.*.address, count.index)}"
      user = "agaveops"
      private_key = "${file(var.openstack_keypair_private_key_path)}"
      timeout = "90s"
    }
  }
  ${TRAINING_USERNAME}/sandbox/ssh

  # copies compose file with network stack to the swarm master
  provisioner "file" {
    content       = "${element(data.template_file.training_sandbox_docker_compose_file.*.rendered, count.index)}"
    destination   = "/home/agaveops/sandbox.compose.${var.attendees[count.index]}.yml"
    connection {
      host = "${element(openstack_networking_floatingip_v2.swarm_tf_floatip_training.*.address, count.index)}"
      user = "agaveops"
      private_key = "${file(var.openstack_keypair_private_key_path)}"
      timeout = "90s"
    }
  }

  # Remote to the training node and register the service. The compose file will ensure that
  # it is bound to run on this training node by mapping the node name into the constraints.
  provisioner "remote-exec" {
    inline = [
      "docker volume create ${var.attendees[count.index]}-training-volume",
      "docker-compose -f /home/agaveops/sandbox.compose.${var.attendees[count.index]}.yml pull",
      "docker-compose -f /home/agaveops/sandbox.compose.${var.attendees[count.index]}.yml up -d ",
    ]
    connection {
      host = "${element(openstack_networking_floatingip_v2.swarm_tf_floatip_training.*.address, count.index)}"
      user = "agaveops"
      private_key = "${file(var.openstack_keypair_private_key_path)}"
      timeout = "90s"
    }
  }
}


# The jupyter training service is started as a Docker Stack on the manager
# node. The stack contains a single file to run a jupyter server container.
# The container is configured with user-specific features, isolated placement
# on a user's dedicated training node, and a persistent volume that will
# suvive container redeployments.
# The container does not publish any ports to the overlay network, rather
# leveraging the swarm-wide traefik reverse proxy to provide internal service
# discovery over the swarm engine and built in docker routing mesh. This allows
# the Jupyter container to be exposed behind a wildcard subdomain and still
# leverage a wildcard SSL cert from Let's Encrypt.
# The user's data is mounted into a persistent volume on the training node
# and the data volume is bind-mounted into each container on a per-user basis.
# A NFS volume driver will be used in the future to persist the user's data
# in spite of node failure.
data "template_file" "training_jupyter_stack_template" {
  template = "${file("templates/training/jupyter.stack.tpl")}"
  count    = "${length(var.attendees)}"

  vars {
      TRAINING_VM_HOSTNAME        = "${var.attendees[count.index]}.${var.training_event}.training.agaveplatform.org"
      TRAINING_EVENT              = "${var.training_event}"
      TRAINING_VM_MACHINE         = "${element(openstack_compute_instance_v2.training_node.*.name, count.index)}"
      TRAINING_VM_ADDRESS         = "${element(openstack_networking_floatingip_v2.swarm_tf_floatip_training.*.address, count.index)}"
      SWARM_OVERLAY_NETWORK_NAME  = "${var.swarm_overlay_network_name}"
      TRAINING_SANBOX_IMAGE       = "${var.sandbox_image}"
      TRAINING_JUPYTER_IMAGE      = "${var.jupyter_image}"
      TRAINING_USERNAME           = "${var.attendees[count.index]}"
      TRAINING_USER_PASS          = "${var.attendee_password}"
  }
}

# Copies docker compose service stack file to the swarm_manager host and
# runs it to create the training stack services for each attendee. Each
# service will be named after the user and pinned to their dedicated VM.
#
resource "null_resource" "training_deploy_jupyter_stack" {
  depends_on = ["null_resource.training_sanbox_launch"]
  count = "${length(var.attendees)}"

  # copies INSTALL.ipynb to the training node for binding into jupyter
  # service the container
  provisioner "file" {
    source       = "templates/training/INSTALL.ipynb"
    destination   = "/home/agaveops/INSTALL.ipynb"
    connection {
      host = "${element(openstack_networking_floatingip_v2.swarm_tf_floatip_training.*.address, count.index)}"
      user = "agaveops"
      private_key = "${file(var.openstack_keypair_private_key_path)}"
      timeout = "300s"
    }
  }

  # copies compose file with network stack to the swarm master
  provisioner "file" {
    content        = "${element(data.template_file.training_jupyter_stack_template.*.rendered, count.index)}"
    destination   = "/home/agaveops/jupyter.stack.${var.attendees[count.index]}.yml"
    connection {
      host = "${openstack_compute_floatingip_associate_v2.swarm_manager.floating_ip}"
      user = "agaveops"
      private_key = "${file(var.openstack_keypair_private_key_path)}"
      timeout = "90s"
    }
  }

  # Remote to the training node and register the service. The compose file will ensure that
  # it is bound to run on this training node by mapping the node name into the constraints.
  provisioner "remote-exec" {
    inline = [
      "docker stack deploy -c /home/agaveops/jupyter.stack.${var.attendees[count.index]}.yml ${var.attendees[count.index]}_training",
    ]
    connection {
      host = "${openstack_compute_floatingip_associate_v2.swarm_manager.floating_ip}"
      user = "agaveops"
      private_key = "${file(var.openstack_keypair_private_key_path)}"
      timeout = "90s"
    }
  }
}
