# Agave Terraform Training Swarm

> Provisions and deploys scalable, configurable Agave SciOps training infrastructure on top of OpenStack and Docker Swarm. An isolated sandbox environment is created for each attendee with their own linux development server, Jupyter server, Jenkins server, vanity public subdomain, build and test host accessible over ssh, and a shared Gitlab server.

## Overview  

The size and composition of the cluster is configurable along three groups:

### Manager nodes

These are the swarm manager nodes. They serve as the entrypoint for all external requests into the cluster. Manager nodes keep the swarm up and running and host the monitoring services and reverse proxy for all web traffic.

The number of managers should always be an odd number. One will be started by default. For production use, three or five is recommended. You can set the number of managers with the `swarm_manager_count` variable in the `00-variables.tf` file.

### Worker nodes

These are worker nodes for the swarm. They are not publicly accessible, but do provide capacity for running support services. Standard Docker networking applies. By default, Any Docker service ports published on containers running on these hosts will be exposed on swarm routing mesh and load balanced across the swarm.

The number of slaves is up to your discretion, and largely depends on the capacity you need to support your training. One will be started by default. You can set the number of workers with the `swarm_slave_count` variable in the `00-variables.tf` file.

### Training nodes

One training node is provisioned for every attendee. Training nodes are identical to worker nodes, but are assigned custom labels telling the scheduler that that they should only run services for a specific attendee.

Each training node runs two containers which provide the attendee's training environment. The first is a sandbox development server. The sandbox container has standard build utilities installed, OpenMP, Python 2 and 3. Both Docker and Singularity are also available for building and publishing images inside the container. The sandbox container serves as a secure command line development environment for each attendee.  

The second container is a Jupyter server. The server extends the official jupyter data science notebook server and provides sample training notebooks that users can follow along with in the training or on their own.

The sandbox and jupyter containers share a common, persistent data volume that will survive container redeployments and shutdown. At this time, it does not survive node failure. a user listed in the `attendees` Terraform variable

Each attendee's training node will be accessible via a vanity subdomain of whatever you set the `wildcard_domain_name` variable to be in your `00-variables.tf` file. By default, this will be `<username>.sc17.training.agaveplatform.org`.


You can set the list of attendees with the `attendees` variable in the `00-variables.tf` file. The list should contain the Agave usernames of each attendee.


## Installation

The provisioning an configuration of the training swarm are done with Terraform. You can install Terraform locally or use the official Docker image to run it.

Pull the official Terraform Docker image
```sh
docker pull hashicorp/terraform:full
```

For native installations, please see the [Terraform Downloads page](https://www.terraform.io/downloads.html).

Next, clone this repository to your local system

```sh
git clone https://github.com/agaveplatform/terraform-training-swarm.git

export TF_HOME="$(pwd)/terraform-training-swarm"
```

Finally, you will need to copy the public and private ssh keys you wish to use to connect to the VM into the `$TF_HOME/keys` directory. These will be copied to the remote host and used to connect for all subsequent remote actions to configure the host. While these keys _may_ be the same as the openstack keypair used to provision the host, they do not have to be. In fact, we recommend that they be different so you can independently rotate your deployment and provisioning keys as needed for your needs.

## Usage

Before running the project you need to update the configuration with your own OpenStack auth credentials. These are provided by the _openrc.sh_ file you download from the OpenStack UI.

> You can read more about how to obtain and source your openrc.sh file on the Jetstream cloud from the [Jetstream Wiki](https://iujetstream.atlassian.net/wiki/spaces/JWT/pages/39682064/Setting+up+openrc.sh).

It is also recommended you customize your deployment by specify your own VM image, number of slaves, workers, attendees, etc. The best way to do this is to edit the `terraform.tfvars` file. Values in this file will override the defaults in the `variables.tf` file. 

> If you do not have a base image to use, please use the default Ubuntu 16.04 image available in your cloud or see the [Agave Image Builder](https://github.com/agaveplatform/packer-ansible) repository for a dead-simple way to build a quality base image to use for your Docker infrastructure on OpenStack.  

Terraform is available as Both a Docker image and binary executable. If you are going to use Docker to run Terraform, set up the following alias, and add your openstack environment to a file, and the examples should all continue to work exactly the same as the native binary.

```bash
alias terraform='docker run -it --rm -w /data --env-file=$(pwd)/.openstack.env -v $(pwd):/data -v $(pwd)/keys:/keys:ro hashicorp/terraform:full'
```  

### Provisioning VMs

To provision the Openstack instances that will host the cluster, run the Terraform plan.

```sh
cd $TF_HOME

# source your openstackrc file to load your auth credentials to openstack into your environment.
. ~/.openstack/openstackrc

# if you are running in Docker, uncomment the following line to copy your openstack environment into a file that can be loaded into the Docker container.
#env | grep "OS_" > .openstack.env

# init your terraform environment.
terraform init

# review the changes that will be made when you run the action plan.
terraform plan

# run the plan and deploy the swarm. We explicitly restrict parallelism to 3 concurrent tasks as the default of 10 tends to make Jetstream sad at us.
terraform apply
```

### Deploying the training swarm

Once the VMs are in plae, run the ansible playbooks against the cluster to configure it. A terraform.py script is included that will read your terraform state file and create a valid dynamic inventory that Ansible will use to configure and deploy the cluster on the instances Terraform provisioned.

```bash
cd ansible
ansible-playbook -i inventory/   
## Tearing down the cluster

To destroy the cluster, run the following command. Terraform will clean up all the instances, networks, security groups, etc that it creates.

```bash
# tear it all down
terraform destroy
```  


For more information on Terraform an its usage, please see the [official documentation](https://www.terraform.io/docs/index.html).

## Development setup

Development is identical to production. Simply edit the templates and variables and rerun Terraform. Terraform is excellent at change management, so when needed, it will reprovision resources to satisfy changes in your plan.

## Roadmap

* Add NFS mount to training nodes to persist data volumes across deployments into the platform's default storage.
* Move from swarm to kubernetes to enable larger training clusters (>256) without requiring network partitioning or external load balancers. 

## Meta

Rion Dooley – [@deardooley](https://twitter.com/deardooley) – deardooley@gmail.com

Distributed under the BSD 3-Clause license. See ``LICENSE`` for more information.

[https://github.com/agaveplatform](https://github.com/agaveplatform)

## Contributing

1. Fork it (<https://github.com/agaveplatform/terraform-training-swarm/fork>)
2. Create your feature branch (`git checkout -b feature/fooBar`)
3. Commit your changes (`git commit -am 'Add some fooBar'`)
4. Push to the branch (`git push origin feature/fooBar`)
5. Create a new Pull Request

<!-- Markdown link & img dfn's -->
