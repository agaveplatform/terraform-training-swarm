# A Gitlab server and prometheus monitoring are deployed into the swarm
# across nodes labled with "slave=yes".
data "template_file" "gitlab_stack" {
  template = "${file("templates/gitlab/gitlab.stack.tpl")}"

  vars {
      TRAINING_EVENT              = "${var.training_event}"
      WILDCARD_DOMAIN_NAME        = "${var.wildcard_domain_name}"
      SWARM_OVERLAY_NETWORK_NAME  = "${var.swarm_overlay_network_name}"
      TRAINING_GITLAB_IMAGE       = "${var.gitlab_image}"
      GITLAB_DB_NAME              = "${var.gitlab_db_name}"
      GITLAB_DB_USERNAME          = "${var.gitlab_db_username}"
      GITLAB_DB_PASSWORD          = "${var.gitlab_db_password}"
  }
}

# Ruby config file for gitlab. This will be written to a master and added
# to the gitlab container(s) as a docker service config.
data "template_file" "gitlab_config" {
  template = "${file("templates/gitlab/gitlab.rb.tpl")}"

  vars {
      TRAINING_EVENT              = "${var.training_event}"
      WILDCARD_DOMAIN_NAME        = "${var.wildcard_domain_name}"
      SWARM_OVERLAY_NETWORK_NAME  = "${var.swarm_overlay_network_name}"
      TRAINING_GITLAB_IMAGE       = "${var.gitlab_image}"
      GITLAB_DB_NAME              = "${var.gitlab_db_name}"
      GITLAB_DB_USERNAME          = "${var.gitlab_db_username}"
      GITLAB_DB_PASSWORD          = "${var.gitlab_db_password}"
  }
}

# Copies docker compose service stack file to the swarm_manager host and
# runs it to create the training stack services for each attendee. Each
# service will be named after the user and pinned to their dedicated VM.
#
resource "null_resource" "deploy_gitlab" {
  depends_on = ["null_resource.swarm_slave_join_cluster"]

  # Remote to the training node and register the service. The compose file will ensure that
  # it is bound to run on this training node by mapping the node name into the constraints.
  provisioner "remote-exec" {
    inline = [
      "mkdir -p /home/agaveops/gitlab",
    ]
    connection {
      host = "${openstack_compute_floatingip_associate_v2.swarm_manager.floating_ip}"
      user = "agaveops"
      private_key = "${file(var.openstack_keypair_private_key_path)}"
      timeout = "90s"
    }
  }

  # writes gitlab.stack to the training node for injection into stack config
  provisioner "file" {
    content       = "${data.template_file.gitlab_stack.rendered}"
    destination   = "/home/agaveops/gitlab/gitlab.stack.yml"
    connection {
      host = "${openstack_compute_floatingip_associate_v2.swarm_manager.floating_ip}"
      user = "agaveops"
      private_key = "${file(var.openstack_keypair_private_key_path)}"
      timeout = "90s"
    }
  }

  # writes gitlab.rb to the master node for injection into stack config
  provisioner "file" {
    content       = "${data.template_file.gitlab_config.rendered}"
    destination   = "/home/agaveops/gitlab/gitlab.rb"
    connection {
      host = "${openstack_compute_floatingip_associate_v2.swarm_manager.floating_ip}"
      user = "agaveops"
      private_key = "${file(var.openstack_keypair_private_key_path)}"
      timeout = "90s"
    }
  }

  # writes grafana.ini to the master node for injection into stack config
  provisioner "file" {
    content       = "${file("templates/gitlab/grafana.ini")}"
    destination   = "/home/agaveops/gitlab/grafana.ini"
    connection {
      host = "${openstack_compute_floatingip_associate_v2.swarm_manager.floating_ip}"
      user = "agaveops"
      private_key = "${file(var.openstack_keypair_private_key_path)}"
      timeout = "90s"
    }
  }

  # writes prometheus.yaml to the master node for injection into stack config
  provisioner "file" {
    content       = "${file("templates/gitlab/prometheus.yaml")}"
    destination   = "/home/agaveops/gitlab/prometheus.yaml"
    connection {
      host = "${openstack_compute_floatingip_associate_v2.swarm_manager.floating_ip}"
      user = "agaveops"
      private_key = "${file(var.openstack_keypair_private_key_path)}"
      timeout = "90s"
    }
  }

  # Remote to the master and register the gitlab stack.
  provisioner "remote-exec" {
    inline = [
      "docker stack deploy -c /home/agaveops/gitlab/gitlab.stack.yml gitlab",
    ]
    connection {
      host = "${openstack_compute_floatingip_associate_v2.swarm_manager.floating_ip}"
      user = "agaveops"
      private_key = "${file(var.openstack_keypair_private_key_path)}"
      timeout = "90s"
    }
  }
}

resource "null_resource" "config_gitlab" {

  # Remote to the master and register the gitlab stack.
  provisioner "local-exec" {
    command = "ansible-playbook -i inventory/terraform.tf ansible/playbooks/gitlab-playbooks/gitlab.yml"
  }
}
//// Clone the training repo from the original github repo
//resource "gitlab_project" "funwave" {
//  count           = "${length(var.attendees)}"
//  base_url        = "https://gitlab.${var.wildcard_domain_name}"
//  token           = "https://gitlab.${var.wildcard_domain_name}"
//
//  name            = "funwave-tvd"
//  description     = "Sample training application"
//  namespace_id    = "${length(var.attendees)}"
//}
//
//resource "gitlab_project_hook" "jenkins" {
//  count                 = "${length(var.attendees)}"
//
//  project               = "${var.attendees[count.index]}/funwave-tvd"
//  url                   = "https://${var.attendees[count.index]}."
//  merge_requests_events = true
//  push_events = true
//  enable_ssl_verification = false
//}