data "template_file" "swarm_host_monitors_template" {
  description = "Renders the Docker Compose file to launch host monitoring containers that publish monitoring and logging data to the services running in the monitoring stack. This is run on every host and started after the monitoring stack is started on the manager node(s)."

  template = "${file("templates/monitoring/monitors.compose.tpl")}"

  vars {
      SWARM_OVERLAY_NETWORK_NAME  = "${var.swarm_overlay_network_name}"
      ELASTICSEARCH_USER          = "${var.elasticsearch_username}"
      ELASTICSEARCH_PASSWORD      = "${var.elasticsearch_password}"
  }
}

data "template_file" "swarm_monitoring_stack_template" {
  description = "Renders the Docker Compose file for monitoring services. This includes the web frontends, elasticsearch, logstash, alertmanager, and visualizer. This should be run exclusively on management node and started first."

  template = "${file("templates/monitoring/monitoring.stack.tpl")}"

  vars {
      SWARM_OVERLAY_NETWORK_NAME  = "${var.swarm_overlay_network_name}"
      ELASTICSEARCH_USER          = "${var.elasticsearch_username}"
      ELASTICSEARCH_PASSWORD      = "${var.elasticsearch_password}"
      GRAFANA_PASSWORD            = "${var.grafana_password}"
      PROMETHEUS_IMAGE            = "${var.prometheus_image}"
      PORTAINER_IMAGE             = "${var.portainer_image}"
      ALERTMANAGER_IMAGE          = "${var.alertmanager_image}"
      SLACK_TOKEN                 = "${var.slack_token}"
  }
}
