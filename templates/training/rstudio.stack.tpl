version: '3.2'

networks:
  ${TRAINING_USERNAME}-training:
  swarm_overlay:
    external:
      name: ${SWARM_OVERLAY_NETWORK_NAME}

volumes:
  ${TRAINING_USERNAME}-training-volume:
    external:
      name: ${TRAINING_USERNAME}-training-volume
  ${TRAINING_USERNAME}-ssh-keygen-volume:
    external:
      name: ${TRAINING_USERNAME}-ssh-keygen-volume


#secrets:
#  training/${TRAINING_USERNAME}/hash:
#    external: true

services:

  ${TRAINING_USERNAME}:
    image: "${TRAINING_JUPYTER_IMAGE}"
    hostname: ${TRAINING_VM_HOSTNAME}
    environment:
      - GRANT_SUDO=yes
      - VM_MACHINE=${TRAINING_VM_MACHINE}
      - VM_IPADDRESS=${TRAINING_VM_ADDRESS}
      - VM_HOSTNAME=${TRAINING_VM_HOSTNAME}
      - USE_TUNNEL=False
      - ENVIRONMENT=training
      - SCRATCH_DIR=/home/${TRAINING_USERNAME}
      - MACHINE_USERNAME=jovyan
      - MACHINE_IP=${TRAINING_VM_ADDRESS}
      - MACHINE_NAME=${TRAINING_USERNAME}
      - MACHINE_PORT=10022
      - DOCKERHUB_NAME=agaveplatform
      - AGAVE_APP_DEPLOYMENT_PATH=agave-deployment
      - AGAVE_CACHE_DIR=/home/${TRAINING_USERNAME}/work/.agave
      - AGAVE_JSON_PARSER=jq
      - AGAVE_SYSTEM_SITE_DOMAIN=localhost
      - AGAVE_TENANT=${AGAVE_TENANT}
      - AGAVE_TENANTS_API_BASEURL=${AGAVE_TENANTS_API_BASEURL}
      - AGAVE_USERNAME=${TRAINING_USERNAME}
      - AGAVE_PASSWORD=${TRAINING_USER_PASS}
      - AGAVE_SYSTEM_HOST=${TRAINING_VM_ADDRESS}
      - AGAVE_SYSTEM_PORT=10022
      - AGAVE_SYSTEM_SITE_DOMAIN=jetstream-cloud.org
      - AGAVE_STORAGE_WORK_DIR=/home/jovyan
      - AGAVE_STORAGE_HOME_DIR=/home/jovyan
      - AGAVE_APP_NAME=funwave-tvd-${TRAINING_EVENT}-${TRAINING_USERNAME}
      - AGAVE_STORAGE_SYSTEM_ID=${TRAINING_EVENT}-storage-${TRAINING_USERNAME}
      - AGAVE_EXECUTION_SYSTEM_ID=${TRAINING_EVENT}-exec-${TRAINING_USERNAME}
    volumes:
      - ${TRAINING_USERNAME}-training-volume:/home/jovyan/work
      - ${TRAINING_USERNAME}-ssh-keygen-volume:/home/jovyan/.ssh
      - /home/agaveops/INSTALL.ipynb:/home/jovyan/INSTALL.ipynb
    networks:
      - swarm_overlay
      - ${TRAINING_USERNAME}-training
    ports:
      - target: 8888
        published: 8888
        protocol: tcp
        mode: host
#   secrets:
#      - training/${TRAINING_USERNAME}/hash
    deploy:
      placement:
        constraints:
          - "node.labels.training.name == ${TRAINING_EVENT}"
          - "node.labels.training.user == ${TRAINING_USERNAME}"
          - "node.labels.environment == training"
      labels:
        - "training.name=${TRAINING_EVENT}"
        - "training.user=${TRAINING_USERNAME}"
        - "environment=training"
        - "traefik.port=8888"
        - "traefik.protocol=http"
        - "traefik.tags=${TRAINING_USERNAME}"
        - "traefik.backend=${TRAINING_USERNAME}-training"
        - "traefik.frontend.rule=Host:${TRAINING_VM_HOSTNAME}"
        - "traefik.docker.network=${SWARM_OVERLAY_NETWORK_NAME}"
      replicas: 1
      resources:
        limits:
          cpus: "1.0"
          memory: 2G
        reservations:
          cpus: "0.01"
          memory: 512M
      restart_policy:
        condition: on-failure
        delay: 5s
        max_attempts: 3
        window: 120s
      update_config:
        parallelism: 1
        delay: 10s
        failure_action: rollback
        monitor: 10s
        max_failure_ratio: 0.3

  ${TRAINING_USERNAME}-opencpu:
    image: agaveplatform/opencpu:latest
    hostname: ${TRAINING_VM_HOSTNAME}
    ports:
      - '8004:8004'
    depends_on:
      - ssh-keygen
    env_file:
      - training.env
    environment:
      - "AGAVE_TENANT_BASE_URL=https://sandbox.agaveplatform.org"
      - "AGAVE_BASE_URL=https://sandbox.agaveplatform.org"
      - "BOOTSTRAP_AGAVE_CLIENT=1"
      - VM_MACHINE=${TRAINING_VM_MACHINE}
      - VM_IPADDRESS=${TRAINING_VM_ADDRESS}
      - VM_HOSTNAME=${TRAINING_VM_HOSTNAME}
      - USE_TUNNEL=False
      - ENVIRONMENT=training
      - SCRATCH_DIR=/home/${TRAINING_USERNAME}
      - MACHINE_USERNAME=jovyan
      - MACHINE_IP=${TRAINING_VM_ADDRESS}
      - MACHINE_NAME=${TRAINING_USERNAME}
      - MACHINE_PORT=10022
      - DOCKERHUB_NAME=agaveplatform
      - AGAVE_APP_DEPLOYMENT_PATH=agave-deployment
      - AGAVE_CACHE_DIR=/home/${TRAINING_USERNAME}/work/.agave
      - AGAVE_JSON_PARSER=jq
      - AGAVE_SYSTEM_SITE_DOMAIN=localhost
      - AGAVE_TENANT=${AGAVE_TENANT}
      - AGAVE_TENANTS_API_BASEURL=${AGAVE_TENANTS_API_BASEURL}
      - AGAVE_USERNAME=${TRAINING_USERNAME}
      - AGAVE_PASSWORD=${TRAINING_USER_PASS}
      - AGAVE_SYSTEM_HOST=${TRAINING_VM_ADDRESS}
      - AGAVE_SYSTEM_PORT=10022
      - AGAVE_SYSTEM_SITE_DOMAIN=jetstream-cloud.org
      - AGAVE_STORAGE_WORK_DIR=/home/jovyan
      - AGAVE_STORAGE_HOME_DIR=/home/jovyan
      - AGAVE_APP_NAME=funwave-tvd-${TRAINING_EVENT}-${TRAINING_USERNAME}
      - AGAVE_STORAGE_SYSTEM_ID=${TRAINING_EVENT}-storage-${TRAINING_USERNAME}
      - AGAVE_EXECUTION_SYSTEM_ID=${TRAINING_EVENT}-exec-${TRAINING_USERNAME}
    networks:
      - swarm_overlay
      - ${TRAINING_USERNAME}-training
    volumes:
      - training-volume:/home/opencpu/work
      - "./opencpu/tutorial:/home/opencpu/tutorial"
    labels:
      - "training.name=${TRAINING_EVENT}"
      - "training.user=${TRAINING_USERNAME}"
      - "environment=training"
      - "traefik.port=8004"
      - "traefik.protocol=http"
      - "traefik.tags=${TRAINING_USERNAME}"
      - "traefik.backend=${TRAINING_USERNAME}-opencpu"
      - "traefik.frontend.rule=Host:${TRAINING_VM_HOSTNAME};PathPrefix=/ocpu"
      - "traefik.docker.network=${SWARM_OVERLAY_NETWORK_NAME}"
      - "traefik.frontend.passHostHeader=true"
    replicas: 1
      resources:
        limits:
          cpus: "1.0"
          memory: 1G
        reservations:
          cpus: "0.01"
          memory: 512M
      restart_policy:
        condition: on-failure
        delay: 5s
        max_attempts: 3
        window: 120s
      update_config:
        parallelism: 1
        delay: 10s
        failure_action: rollback
        monitor: 10s
        max_failure_ratio: 0.3