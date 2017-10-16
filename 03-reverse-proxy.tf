# Renders the traefik stack file which configures and runs the Traefik reverse
# proxy as a Docker Swarm service, exposing all http notebooks via a dynamic
# subdomain per user. This should be run on publicly exposed hosts and started
# after the monitoring stack is started on the manager node(s).
data "template_file" "swarm_reverse_proxy_stack" {
  template = "${file("templates/traefik/traefik.stack.tpl")}"

  vars {
      SWARM_OVERLAY_NETWORK_NAME  = "${var.swarm_overlay_network_name}"
      TRAINING_EVENT              = "${var.training_event}"
      WILDCARD_DOMAIN_NAME        = "${var.wildcard_domain_name}"
  }
}

# Renders the traefik.toml used set the runtime Traefik reverse proxy
# configuration.
data "template_file" "swarm_reverse_proxy_config" {
  template = "${file("templates/traefik/traefik.toml.tpl")}"

  vars {
      WILDCARD_DOMAIN_NAME        = "${var.wildcard_domain_name}"
  }
}

# Deploy reverse proxy stack file to the swarm masters an start the service on
# the leader node. Should run after monitoring stack is up and netwoks are
# provisioned.
resource "null_resource" "deploy_reverse_proxy" {
  depends_on = ["null_resource.swarm_manager_init_swarm"]

  # Create the traefik config directory on the remote host
  provisioner "remote-exec" {
    inline = [
      "mkdir -p /home/agaveops/traefik",
    ]
    connection {
      host = "${openstack_compute_floatingip_associate_v2.swarm_manager.floating_ip}"
      user = "agaveops"
      private_key = "${file(var.openstack_keypair_private_key_path)}"
      timeout = "90s"
    }
  }

  # copies the traefik ssl certs to the swarm manager
  provisioner "file" {
    source      = "templates/traefik/ssl"
    destination = "/home/agaveops/traefik/ssl"
    connection {
      host = "${openstack_compute_floatingip_associate_v2.swarm_manager.floating_ip}"
      user = "agaveops"
      private_key = "${file(var.openstack_keypair_private_key_path)}"
      timeout = "90s"
    }
  }

  # copies rendered reverse proxy compose stack file to the swarm manager
  provisioner "file" {
    content      = "${data.template_file.swarm_reverse_proxy_config.rendered}"
    destination = "/home/agaveops/traefik/traefik.toml"
    connection {
      host = "${openstack_compute_floatingip_associate_v2.swarm_manager.floating_ip}"
      user = "agaveops"
      private_key = "${file(var.openstack_keypair_private_key_path)}"
      timeout = "90s"
    }
  }

  # Copies rendered reverse proxy compose stack file to the swarm manager
  provisioner "file" {
    content      = "${data.template_file.swarm_reverse_proxy_stack.rendered}"
    destination = "/home/agaveops/traefik/traefik.stack.yml"
    connection {
      host = "${openstack_compute_floatingip_associate_v2.swarm_manager.floating_ip}"
      user = "agaveops"
      private_key = "${file(var.openstack_keypair_private_key_path)}"
      timeout = "90s"
    }
  }

  # Launch the Traefik reverse proxy on the swarm manager using the compose
  # stack file
  provisioner "remote-exec" {
    inline = [
      "docker stack deploy -c traefik/traefik.stack.yml traefik",
      "echo sleeping for 15 seconds to allow the stack an network to propagate",
      "sleep 15",
      "docker service ps --no-trunc traefik_traefik",
    ]
    connection {
      host = "${openstack_compute_floatingip_associate_v2.swarm_manager.floating_ip}"
      user = "agaveops"
      private_key = "${file(var.openstack_keypair_private_key_path)}"
      timeout = "90s"
    }
  }

  # Remove the traefik service and delete the configs on resource destruction
  # This might not be a great idea as it will take down traffic suddently. It
  # Might be better to leave it commented out and allow swarm to redeploy the
  # service gracefully instead.
  # provisioner "remote-exec" {
  #   on_destroy  = true
  #   inline = [
  #     "docker stack rm traefik",
  #     "rm -rf traefik"
  #   ]
  #   connection {
  #     host = "${openstack_compute_floatingip_associate_v2.swarm_manager.floating_ip}"
  #     user = "agaveops"
  #     private_key = "${file(var.openstack_keypair_private_key_path)}"
  #     timeout = "90s"
  #   }
  # }
}
