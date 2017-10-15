#!/bin/bash
# Script that will run at first boot via Openstack
# using user_data via cloud-init.

chown agaveops:agaveops /home/agaveops/docker-compose.yml

su - agaveops -c "docker swarm init"
su - agaveops -c "docker swarm join-token --quiet worker > /home/agaveops/worker-token"
su - agaveops -c "docker swarm join-token --quiet manager > /home/agaveops/manager-token"

su - agaveops -c "docker stack deploy --compose-file /home/agaveops/docker-compose.yml monitoring > /dev/null"
