# Renders the Docker Compose file to launch host monitoring containers that
# publish monitoring and logging data to the services running in the monitoring
# stack. This is run on every host and started after the monitoring stack is
# started on the manager node(s).
data "template_file" "swarm_host_monitors_template" {
  template = "${file("templates/monitoring/monitors.compose.tpl")}"

  vars {
      SWARM_OVERLAY_NETWORK_NAME  = "${var.swarm_overlay_network_name}"
      ELASTICSEARCH_USER          = "${var.elasticsearch_username}"
      ELASTICSEARCH_PASSWORD      = "${var.elasticsearch_password}"
  }
}

# Renders the Docker Compose file for monitoring services. This includes the web
# frontends, elasticsearch, logstash, alertmanager, and visualizer. This should
# be run exclusively on management node and started first.
data "template_file" "swarm_monitoring_stack_template" {
  template = "${file("templates/monitoring/monitoring.stack.tpl")}"

  vars {
      SWARM_OVERLAY_NETWORK_NAME  = "${var.swarm_overlay_network_name}"
      ELASTICSEARCH_USER          = "${var.elasticsearch_username}"
      ELASTICSEARCH_PASSWORD      = "${var.elasticsearch_password}"
      GRAFANA_IMAGE               = "${var.grafana_image}"
      GRAFANA_PASSWORD            = "${var.grafana_admin_password}"
      PROMETHEUS_IMAGE            = "${var.prometheus_image}"
      PORTAINER_IMAGE             = "${var.portainer_image}"
      ALERTMANAGER_IMAGE          = "${var.alertmanager_image}"
      SLACK_TOKEN                 = "${var.slack_token}"
      WILDCARD_DOMAIN_NAME        = "${var.wildcard_domain_name}"
  }
}

# Deploys frontend monitoring services to swarm cluster. This is where we launch
# viz, grafana, kibana, portainer, etc.
resource "null_resource" "swarm_manager_deploy_monitoring_stack" {
  depends_on = ["null_resource.swarm_manager_init_swarm"]

  # Copy rendered host monitoring compose file to the slave
  provisioner "file" {
    content      = "${data.template_file.swarm_monitoring_stack_template.rendered}"
    destination = "/home/agaveops/monitoring.stack.yml"
    connection {
      host = "${openstack_compute_floatingip_associate_v2.swarm_manager.floating_ip}"
      user = "agaveops"
      private_key = "${file(var.openstack_keypair_private_key_path)}"
      timeout = "90s"
    }
  }

  # Launch the host monitoring docker containers by invoking docker compose
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

# Launch host monitor containers on leader. We deploy as a compose file and
# attach to the overlay network manually because the Docker service API does not
# support privileged flags on services, which are needed to do host monitoring.
resource "null_resource" "swarm_master_init_host_monitors" {
  depends_on = ["null_resource.swarm_slave_join_cluster", "null_resource.deploy_reverse_proxy"]

  # Copy rendered host monitoring compose file to the manager
  provisioner "file" {
    content      = "${data.template_file.swarm_host_monitors_template.rendered}"
    destination = "/home/agaveops/monitors.compose.yml"
    connection {
      host = "${openstack_compute_floatingip_associate_v2.swarm_manager.floating_ip}"
      user = "agaveops"
      private_key = "${file(var.openstack_keypair_private_key_path)}"
      timeout = "90s"
    }
  }

  # Launch the host monitoring docker containers by invoking docker compose
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

# Launch host monitor containers on managerx nodes. We deploy as a compose file
# and attach to the overlay network manually because the Docker service API does
# not support privileged flags on services, which are needed to do host
# monitoring.
resource "null_resource" "swarm_masterx_init_host_monitors" {
  depends_on = ["null_resource.swarm_managerx_join_cluster", "null_resource.deploy_reverse_proxy"]
  count = "${var.swarm_manager_count - 1}"

  # Copy rendered host monitoring compose file to the slave
  provisioner "file" {
    content      = "${data.template_file.swarm_host_monitors_template.rendered}"
    destination = "/home/agaveops/monitors.compose.yml"
    connection {
      host = "${element(openstack_compute_floatingip_associate_v2.swarm_managerx.*.floating_ip, count.index)}"
      user = "agaveops"
      private_key = "${file(var.openstack_keypair_private_key_path)}"
      timeout = "90s"
    }
  }

  # Launch the host monitoring docker containers by invoking docker compose
  # with the monitoring compose file.
  provisioner "remote-exec" {
    inline = [
      "docker-compose -f monitors.compose.yml up -d",
    ]
    connection {
      host = "${element(openstack_compute_floatingip_associate_v2.swarm_managerx.*.floating_ip, count.index)}"
      user = "agaveops"
      private_key = "${file(var.openstack_keypair_private_key_path)}"
      timeout = "90s"
    }
  }
}

# Launch host monitor containers on slave nodes. We deploy as a compose file and
# attach to the overlay network manually because the Docker service API does not
# support privileged flags on services, which are needed to do host monitoring.
resource "null_resource" "swarm_slave_init_host_monitors" {
  depends_on = ["null_resource.swarm_slave_join_cluster", "null_resource.deploy_reverse_proxy"]
  count = "${var.swarm_slave_count}"

  # Copy rendered host monitoring compose file to the slave
  provisioner "file" {
    content      = "${data.template_file.swarm_host_monitors_template.rendered}"
    destination = "/home/agaveops/monitors.compose.yml"
    connection {
      host = "${element(openstack_compute_floatingip_associate_v2.swarm_slave.*.floating_ip, count.index)}"
      user = "agaveops"
      private_key = "${file(var.openstack_keypair_private_key_path)}"
      timeout = "90s"
    }
  }

  # Launch the host monitoring docker containers by invoking docker compose
  # with the monitoring compose file.
  provisioner "remote-exec" {
    inline = [
      "docker-compose -f monitors.compose.yml up -d",
    ]
    connection {
      host = "${element(openstack_compute_floatingip_associate_v2.swarm_slave.*.floating_ip, count.index)}"
      user = "agaveops"
      private_key = "${file(var.openstack_keypair_private_key_path)}"
      timeout = "90s"
    }
  }
}

# Launch host monitor containers on training nodes. We deploy as a compose file
# and attach to the overlay network manually because the Docker service API does
# not support privileged flags on services, which are needed to do host
# monitoring.
resource "null_resource" "training_node_init_host_monitors" {
  depends_on = ["null_resource.training_node_join_cluster", "null_resource.deploy_reverse_proxy"]
  count = "${length(var.attendees)}"

  # Copy rendered host monitoring compose file to the slave
  provisioner "file" {
    content      = "${data.template_file.swarm_host_monitors_template.rendered}"
    destination = "/home/agaveops/monitors.compose.yml"
    connection {
      host = "${element(openstack_compute_floatingip_associate_v2.training_node.*.floating_ip, count.index)}"
      user = "agaveops"
      private_key = "${file(var.openstack_keypair_private_key_path)}"
      timeout = "90s"
    }
  }

  # Launch the host monitoring docker containers by invoking docker compose
  # with the monitoring compose file.
  provisioner "remote-exec" {
    inline = [
      "docker-compose -f monitors.compose.yml up -d",
    ]
    connection {
      host = "${element(openstack_compute_floatingip_associate_v2.training_node.*.floating_ip, count.index)}"
      user = "agaveops"
      private_key = "${file(var.openstack_keypair_private_key_path)}"
      timeout = "90s"
    }
  }
}
