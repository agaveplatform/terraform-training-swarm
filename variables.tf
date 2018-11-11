/***********************************************************
 * OpenStack connectivity
 ***********************************************************/

//variable "openstack_user_name" {
//  description = "The username for the Tenant."
//  default  = ""
//}
//
//variable "openstack_tenant_name" {
//  description = "The name of the Tenant."
//  default  = ""
//}
//
//variable "openstack_password" {
//  description = "The password for the Tenant."
//  default  = ""
//}
//
//variable "openstack_auth_url" {
//  description = "The endpoint url to connect to OpenStack."
//  default  = ""
//}
//
//variable "openstack_project_name" {
//  description = "The project name of the Tenant."
//  default  = ""
//}
//
//variable "openstack_project_id" {
//  description = "The project i of the Tenant."
//  default  = ""
//}
//
//variable "openstack_region" {
//  description = "The region of the Tenant."
//  default  = ""
//}

variable "openstack_image" {
  description = "The uuid of the image to use when launch vms"
  default = ""
}

variable "openstack_ssh_username" {
  description = "The username to use when remotely ssh into an instance"
  default = "ubuntu"
}

variable "openstack_keypair_public_key_path" {
  description = "The name of the openstack public key to stage to the authorized_keys file on remote resources"
  default = "keys/key.pub"
}


variable "openstack_keypair_private_key_path" {
  description = "The name of the openstack private key to use when connecting to remote resources."
  default = "keys/key.pem"
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
    m1_small = "2"
    m1_medium = "3"
    m1_large = "4"
    m1_xlarge = "5"
    m1_xxlarge = "6"
  	s1_large = "14"
  	s1_xlarge = "15"
  	s1_xxlarge = "16"

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

variable "wildcard_floating_ip_address" {
  description = "The openstack floating ip address of the training cluster reverse proxy/load balancer"
  default = "192.168.0.1"
}

 /***********************************************************
  * Swarm Configuration Parameters
  ***********************************************************/

variable "swarm_worker_count" {
  description = "The number of swarm worker nodes to provision."
  default  = 1
}

variable "swarm_manager_count" {
  description = "The number of swarm master nodes to provision."
  default  = 1
}

/***********************************************************
 * Training parameters
 ***********************************************************/

variable "training_event" {
  description = "The short name of the training event. This will be used to label nodes and constrain system deployment in the event multiple hosts are used"
  default = "sc18"
}

variable "attendees" {
  description = "A list of the training attendees. One swarm worker VM will be started for each attendee in addition to the base swarm footprint. Attendee sandboxes will be provisioned on the VM with their username. Valid client keys and auth/refresh tokens will be generated and injected into their environment."
  type        = "list"
  default     = ["training001"]
}


