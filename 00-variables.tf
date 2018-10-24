/***********************************************************
 * OpenStack connectivity
 ***********************************************************/

variable "openstack_user_name" {
  description = "The username for the Tenant."
  default  = ""
}

variable "openstack_tenant_name" {
  description = "The name of the Tenant."
  default  = ""
}

variable "openstack_password" {
  description = "The password for the Tenant."
  default  = ""
}

variable "openstack_auth_url" {
  description = "The endpoint url to connect to OpenStack."
  default  = ""
}

variable "openstack_project_name" {
  description = "The project name of the Tenant."
  default  = ""
}

variable "openstack_project_id" {
  description = "The project i of the Tenant."
  default  = ""
}

variable "openstack_region" {
  description = "The region of the Tenant."
  default  = ""
}

variable "openstack_images" {
  description = "The uuid of the public gateway"
  type = "map"
  default = {
  		ubuntu1604 = ""
  }
}

variable "openstack_network_name" {
  description = "The name of the network to create. This will be used to generate a random name. Changing this value, changes the network and forces a regeneration"
  default = "swarm_tf_network_1"
}

variable "openstack_network_subnet_name" {
  description = "The name of the network subnet to create. This will be used to generate a random name. Changing this value, changes network subnet and forces a regeneration"
  default = "swarm_tf_subnet_1"
}

variable "openstack_router" {
  description = "The name of the router to create. This will be used to generate a random name. Changing this value, changes the plan router and forces a regeneration."
  default = "swarm_tf_router1"
}

variable "openstack_secgroup" {
  description = "The name of the network to create. This will be used to generate a random name. Changing this value, changes the plan security group and forces a regeneration."
  default = "swarm_tf_secgroup_1"
}

variable "openstack_keypair_name" {
	description = "The name of the openstack keypair to create "
  default = "agave-tf-swarm"
}

variable "openstack_keypair_public_key_path" {
  description = "The name of the openstack public key to stage to the authorized_keys file on remote resources"
  default = "/keys/key.pub"
}


variable "openstack_keypair_private_key_path" {
  description = "The name of the openstack private key to use when connecting to remote resources."
  default = "/keys/key.pem"
}


/**
* OpenStack Flavors
* Note: Specific to IU jetstream as of 10/4/17
*
* ID   Name       VCPU    Memory Disk(GB)
* 1    m1.tiny       1      2048       8
* 2    m1.small      2      4096      20
* 3    m1.medium     6     16384      60
* 4    m1.large     10     30720      60
* 5    m1.xlarge    24     61440      60
* 6    m1.xxlarge   44    122880      60
* 14   s1.large     10     30720     120
* 15   s1.xlarge    24     61440     240
* 16   s1.xxlarge   44    122880     480
*/
variable "openstack_flavor" {
	description = "The uuid of the public gateway"
  type = "map"
	default = {
  	m1_tiny = "1"
  	s1_large = "14"
  	s1_xlarge = "15"
  	s1_xxlarge = "16"
  	m1_small = "2"
  	m1_medium = "3"
  	m1_large = "4"
  	m1_xlarge = "5"
  	m1_xxlarge = "6"
  }
}

variable "openstack_external_gateway_id" {
	description = "The uuid of the public gateway"
	default = "4367cd20-722f-4dc2-97e8-90d98c25f12e"
}

variable "openstack_network_subnet_cidr" {
  description = "The cidr of the network subnet to create"
  default = "10.10.0.0/24"
}


 /***********************************************************
  * Swarm Configuration Parameters
  ***********************************************************/

variable "swarm_slave_count" {
  description = "The number of swarm slave nodes to provision."
  default  = 1
}

variable "swarm_manager_count" {
  description = "The number of swarm master nodes to provision."
  default  = 1
}

variable "swarm_overlay_network_name" {
  description = "The name of the overlay network for swarm to route traffic."
  default  = "swarm-overlay"
}

variable "swarm_environment" {
  description = "The environment for which to configure the swarm cluster. This will be passed to ansible to use in its logic."
  default  = "training"
}

/************* Move to Ansible roles? *************/

variable "sandbox_image" {
  description = "The fully qualified sandbox image to use."
  default  = "agaveplatform/training-sandbox:latest"
}

variable "jupyter_image" {
  description = "The fully qualified jupyter image to use."
  default  = "agaveplatform/jupyter-notebook:5.2"
}

variable "gitlab_image" {
  description = "The fully qualified gitlab image to use."
  default  = "gitlab/gitlab-ce:10.3.3-ce.0"
}

variable "gitlab_db_name" {
  description = "The gitlab postgresql database name for the service user"
  default = "gitlab"
}

variable "gitlab_db_username" {
  description = "The gitlab postgresql user with whom to authenticate"
  default = "gitlab"
}

variable "gitlab_db_password" {
  description = "The gitlab postgresql password for the service user"
  default = "gitlab"
}

variable "gitlab_token" {
  description = "The gitlab admin token to stage training accounts."
  default = "96e4440f0873e44b4641e0749d1ea80a5893276c"
}

variable "gitlab_training_repository_source" {
  description = "The location of the source repository to fork into gitlab for each user."
  default     = "https://github.com/agavetraining/funwave-tvd"
}

variable "portainer_image" {
  description = "The fully qualified portainer image to use."
  default  = "portainer/portainer:latest"
}

variable "traefik_image" {
  description = "The traefik image to use as the reverse proxy to the training hosts."
  default = "traefik:latest"
}

variable "grafana_image" {
  description = "The grafana image to use for visualizing prometheus data"
  default = "basi/grafana:v4.1.1"
}

variable "alertmanager_image" {
  description = "The grafana image to use for visualizing prometheus data"
  default = "basi/alertmanager:v0.1.0"
}

variable "prometheus_image" {
  description = "The prometheus image to use for visualizing prometheus data"
  default = "basi/prometheus-swarm:v0.4.3"
}

variable "elasticsearch_username" {
  description = "The elasticsearch user with whom to authenticate"
  default = ""
}

variable "elasticsearch_password" {
  description = "The elasticsearch password for the service user"
  default = ""
}

variable "grafana_admin_password" {
  description = "The grafana ui admin password"
  default = "admin"
}

variable "slack_token" {
  description = "The grafana password for the admin user"
  default = "YOURTOKENHERE"
}


/***********************************************************
 * VM connectivity
 ***********************************************************/

variable "ssh_user" {
  description = "The login user on the VM of the Tenant."
  default  = "agaveops"
}

variable "ssh_become" {
  description = "The login user on the VM of the Tenant."
  default  = false
}

variable "ssh_become_user" {
  description = "The login user on the VM of the Tenant."
  default  = "root"
}

/***********************************************************
 * Training parameters
 ***********************************************************/

variable "training_event" {
  description = "The short name of the training event. This will be used to label nodes and constrain system deployment in the event multiple hosts are used"
  default = "sc17"
}

variable "training_event_git_url" {
  description = "The url of the git repository where the training materials can be found."
  default     = "https://github.com/uh-ci/agave_workshop_20180419"
}

variable "attendees" {
  description = "A list of the training attendees. One Swarm slave VM will be started for each attendee in addition to the base swarm footprint. Attendee sandboxes will be provisioned on the VM with their username. Valid client keys and auth/refresh tokens will be generated and injected into their environment."
  default     = ["stevenrbrandt","ktraxler","jfonner","dooley"]
}

variable "attendee_password" {
  description = "The default password for the attendees to use when logging into their jupyter hub installs."
  default     = "changeit"
}

variable "wildcard_domain_name" {
  description = "The wildcard subdomain created for this training event"
  default     = "sc17.training.agaveplatform.org"
}

/***********************************************************
 * Automated SSL generation with Lets Encrypt
 ***********************************************************/

variable "acme_email" {
  description = "The email address sent to Lets Encrypt when requesting a SSL cert"
  default     = "ssl@agaveplatform.org"
}

variable "use_production_acme_server" {
  description = "The wildcard subdomain created for this training event"
  default     = false
}


/***********************************************************
 * Agave Platform Tenant Configuration
 ***********************************************************/

variable "agave_tenant" {
  description = "The code of the tenant to use during the tutorial. The tenant should be resolvable from the url given buy the agave_tenants_api_baseurl variable."
  default     = "agave.prod"
}

variable "agave_tenants_api_baseurl" {
  description = "The discovery url of the tenants api to use when bootstrapping the client configs, etc."
  default     = "https://agaveapi.co/tenants"
}




