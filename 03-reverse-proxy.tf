
data "template_file" "swarm_reverse_proxy" {
  description = "Renders the traefik stack file which configures and runs a Traefik reverse proxy to expose all http notebooks via a dynamic subdomain per user. This should be run on publicy exposed hosts and started after the monitoring stack is started on the manager node(s)."

  template = "${file("templates/traefik/traefik.stack.tpl")}"

  vars {
      SWARM_OVERLAY_NETWORK_NAME  = "${var.swarm_overlay_network_name}"
      TRAINING_EVENT              = "${var.training_event}"
  }
}


resource "null_resource" "deploy_reverse_proxy" {
  description = "Deploy reverse proxy stack file to the swarm masters an start the service on the leader node."

  depends_on = ["null_resource.swarm_manager_deploy_monitoring_stack"]

  # copies the traefik config files and ssl certs to the swarm manager
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

  # copies resolved reverse proxy compose stack file to the swarm manager
  provisioner "file" {
    content      = "${template_file.swarm_reverse_proxy.resolved}"
    destination = "/home/agaveops/traefik.stack.yml"
    connection {
      host = "${openstack_compute_floatingip_associate_v2.swarm_manager.floating_ip}"
      user = "agaveops"
      private_key = "${file(var.openstack_keypair_private_key_path)}"
      timeout = "90s"
    }
  }

  # launch the Traefik reverse proxy on the swarm manager using the compose stack file
  provisioner "remote-exec" {
    description = "Launch the Traefik reverse proxy on the swarm manager using the compose stack file"
    inline = [
      "docker stack deploy -d monitors.compose.yml up -d",
    ]
    connection {
      host = "${openstack_compute_floatingip_associate_v2.swarm_manager.floating_ip}"
      user = "agaveops"
      private_key = "${file(var.openstack_keypair_private_key_path)}"
      timeout = "90s"
    }
  }
}
