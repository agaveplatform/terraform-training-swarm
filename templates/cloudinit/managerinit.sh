#!/bin/bash
# Script that will run at first boot via Openstack
# using user_data via cloud-init.

# Copy Tokens from master1 => masterX
#sudo scp -o StrictHostKeyChecking=no -o NoHostAuthenticationForLocalhost=yes -o UserKnownHostsFile=/dev/null -i /home/agaveops/.ssh/key.pem agaveops@${swarm_manager}:/home/agaveops/manager-token /home/agaveops/manager-token

# Copy docker-compose.yml file
#sudo scp -o StrictHostKeyChecking=no -o NoHostAuthenticationForLocalhost=yes -o UserKnownHostsFile=/dev/null -i /home/agaveops/.ssh/key.pem agaveops@${swarm_manager}:/home/agaveops/docker-compose.yml /home/agaveops/docker-compose.yml
#sudo docker swarm join --token $(cat /home/agaveops/manager-token) ${swarm_manager}

sudo scp -o StrictHostKeyChecking=no -o NoHostAuthenticationForLocalhost=yes -o UserKnownHostsFile=/dev/null -i /home/agaveops/.ssh/key.pem agaveops@${swarm_manager}:/home/agaveops/worker-token /home/agaveops/manager-token
chown agaveops:agaveops /home/agaveops/manager-token
su - agaveops -c "docker swarm join --token $(cat /home/agaveops/manager-token) ${swarm_manager}"
