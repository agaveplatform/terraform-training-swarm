# Provider block for github. This is where we provide orgnaization and auth
# details to connect to the training organization
provider "github" {
  token        = "${var.github_token}"
  organization = "${var.github_organization}"
}


# Creates a github repository for each attendee. The training repo will be a
# blank repository to which we will add the training application code.
resource "github_repository" "training_repo" {
  depends_on = ["null_resource.training_deploy_jupyter_stack"]
  count = "${length(var.attendees)}"

  name        = "${var.attendees[count.index]}-funwave-tvd"
  description = "Fork of ${var.training_app_repository} "
  homepage_url = "https://${var.attendees[count.index]}.${var.wildcard_domain_name}"

  private = false
}

module "training_account" "individual" {
  count = "${length(var.attendees)}"

  source = "modules/training_account"
  username "${var.attendees[count.index]}"
}

# generates ssh keys for each attendee and stages them to the training node
# for use as deployment keys
resouce "null_resource" "training_repo_keygen" {
  count = "${length(var.attendees)}"

  # # generates deployment keys for the training node to push to github
  # provisioner "local-exec" {
  #   command = "ssh-keygen -q -f keys/deployment/${var.attendees[count.index]}/github -C 'Deployment keys for ${element(github_repository.training_repo.*.name, count.index)}' -I '${var.attendees[count.index]}.${var.wildcard_domain_name}' -V -2d:+1w -N ''"
  # }

  training_account

  # copies deployment key foldes for every attendee to the swarm master.
  provisioner "file" {
    content      = "${element(tls_private_key.example.*.public_key_openssh, count.index)}"
    destination = "/home/agaveops/.ssh/github.pub"
    connection {
      host = "${element(openstack_networking_floatingip_v2.swarm_tf_floatip_training.*.address, count.index)}"
      user = "agaveops"
      private_key = "${file(var.openstack_keypair_private_key_path)}"
      timeout = "90s"
    }
  }
}

# # stages training deployment keys to the swarm leader and injects them as
# # secrets into the swarm. They are then able to be mounted to each service
# # in the training stack.
# # NOTE: currently swarm will not allow setting of privilege mode on services
# # thus, we cacnnot use secrets as we need to launch the sandbox with compose.
# resouce "null_resource" "training_node_deployment_secrets" {
#
#   depends_on = ["null_resource.training_repo_deployment_keygen"]
#   # copies deployment key foldes for every attendee to the swarm master.
#   provisioner "file" {
#     source      = "keys/deployment"
#     destination = "/home/agaveops/.ssh/"
#     connection {
#       host = "${element(openstack_networking_floatingip_v2.swarm_tf_floatip_training.*.address, count.index)}"
#       user = "agaveops"
#       private_key = "${file(var.openstack_keypair_private_key_path)}"
#       timeout = "90s"
#     }
#   }
#
#   # Create docker secrets on the swarm master for each attendee's deployment
#   # keys. These will be added to their sandbox at deployment time
#   provisioner "remote-exec" {
#     inline = [
#       "for i in $(ls -l /home/agaveops/.ssh/deployment | grep '^d' | awk '{print $9}'); do docker secret create $i_deployment_key --label 'environment=training' --label 'training.name=${var.training_event}' --label 'training.user=$i' --label 'repository.type=github' --label 'respository.name=$i-funwave-tvd' ./deployment/$i/github",
#     ]
#     connection {
#       host = "${openstack_compute_floatingip_associate_v2.swarm_manager.floating_ip}"
#       user = "agaveops"
#       private_key = "${file(var.openstack_keypair_private_key_path)}"
#       timeout = "90s"
#     }
#   }
# }

# adds each attendee's public deployment key to the github repo we just created
# for them. This allows them to push code changes to their own git repository.
resource "github_repository_deploy_key" "training_repo_github_deploy_key" {
  count = "${length(var.attendees)}"

  title = "${var.attendees[count.index]}.${var.wildcard_domain_name}"
  repository = "${element(github_repository.training_repo.*.name, count.index)}"
  key = "${file(keys/deployment/${var.attendees[count.index]}/github.pub)}"
  can_push = "true"
}

# adds push webhook to the attendee's github repository to tell their Jenkins
# server when a new commit is pushed. The attendee's jenkins server is running
# under the same vanity url as their notebook, and proxied by the global Traefik
# server. To avoid namespace collisions and properly map ports, Jenkins runs on
# the /jenkins subpath.
resource "github_repository_webhook" "training_repo_github_webhook" {
  repository = "${github_repository.repo.name}"

  name = "web"

  configuration {
    url          = "https://${var.attendees[count.index]}.${var.wildcard_domain_name}/jenkins"
    content_type = "form"
    insecure_ssl = true
  }

  active = false

  events = ["push"]
}

# The automation services are started as a Docker Stack on the manager
# node. The stack contains a single file to run a jenkins container an docker.
# registry. The container is configured with user-specific features, isolated
# placement on a user's dedicated training node, and a persistent volume that
# will suvive container redeployments.
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
  template = "${file("templates/automation/automation.stack.tpl")}"
  count    = "${length(var.attendees)}"

  vars {
      TRAINING_VM_HOSTNAME        = "${var.attendees[count.index]}.${var.training_event}.training.agaveplatform.org"
      TRAINING_EVENT              = "${var.training_event}"
      TRAINING_VM_MACHINE         = "${element(openstack_compute_instance_v2.training_node.*.name, count.index)}"
      TRAINING_VM_ADDRESS         = "${element(openstack_networking_floatingip_v2.swarm_tf_floatip_training.*.address, count.index)}"

      SWARM_OVERLAY_NETWORK_NAME  = "${var.swarm_overlay_network_name}"

      TRAINING_JENKINS_IMAGE       = "${var.jenkins_image}"
      TRAINING_REGISTRY_IMAGE      = "${var.docker_registry_image}"
      TRAINING_REPOSITORY_NAME    = "${element(github_repository.training_repo.*.name, count.index)}"
      TRAINING_REPOSITORY_SSH_CLONE_URL    = "${element(github_repository.training_repo.*.ssh_clone_url , count.index)}"
      TRAINING_USERNAME           = "${var.attendees[count.index]}"
      TRAINING_USER_PASS          = "${var.attendee_password}"
  }
}


# Copies docker compose file for the automation stack file to the swarm_manager
# and runs it to create the automation stack services for each attendee. Each
# service will be namespaced for the attenee and pinned to their dedicated VM.
#
resource "null_resource" "training_deploy_automation_stack" {
  depends_on = ["null_resource.training_sanbox_launch"]
  count = "${length(var.attendees)}"

  # copies INSTALL.ipynb to the training node for binding into jupyter
  # service the container
  provisioner "file" {
    content       = "${"
    destination   = "/home/agaveops/INSTALL.ipynb"
    connection {
      host = "${element(openstack_networking_floatingip_v2.swarm_tf_floatip_training.*.address, count.index)}"
      user = "agaveops"
      private_key = "${file(var.openstack_keypair_private_key_path)}"
      timeout = "300s"
    }
  }

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
resource "null_resource" "training_deploy_automation_stack" {
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
