version: '3.2'

networks:
  training:
  swarm_overlay:
    external:
      name: ${SWARM_OVERLAY_NETWORK_NAME}

volumes:
  ${TRAINING_USERNAME}-training-volume:
    external:
      name: ${TRAINING_USERNAME}-training-volume

services:

  ${TRAINING_USERNAME}:
    image: ${TRAINING_JUPYTER_IMAGE}
    command: start-notebook.sh --NotebookApp.token=''
    hostname: ${TRAINING_VM_HOSTNAME}
#    extra_hosts:
#      - "sandbox:${TRAINING_VM_ADDRESS}"
#      - "${TRAINING_VM_HOSTNAME}-sandbox:${TRAINING_VM_ADDRESS}"
    environment:
      - VM_MACHINE=${TRAINING_VM_MACHINE}
      - VM_IPADDRESS=${TRAINING_VM_ADDRESS}
      - VM_HOSTNAME=${TRAINING_VM_HOSTNAME}
      - USE_TUNNEL=False
      - ENVIRONMENT=training
      - AGAVE_CACHE_DIR=/home/jovyan/work/.agave
      - OAUTH_TOKEN_URL=https://public.agaveapi.co/token
      - OAUTH_CALLBACK_URL=http://${TRAINING_VM_HOSTNAME}
    volumes:
      - ${TRAINING_USERNAME}-training-volume:/home/jovyan/work
    networks:
      - training
      - swarm_overlay
    ports:
      - 8005:8005
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
        - "traefik.port=8005"
        - "traefik.protocol=http"
        - "traefik.frontend.rule=Host:${TRAINING_VM_HOSTNAME}"
        - "traefik.backend.loadbalancer.sticky=true"
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
