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

services:

  ${TRAINING_USERNAME}-sandbox:
    image: ${TRAINING_SANBOX_IMAGE}
    hostname: ${TRAINING_VM_HOSTNAME}
    privileged: True
    ports:
      - '10022:22'
    environment:
      - VM_MACHINE=${TRAINING_VM_HOSTNAME}
      - VM_IPADDRESS=${TRAINING_VM_ADDRESS}
      - VM_HOSTNAME=${TRAINING_VM_HOSTNAME}
      - VM_SSH_PORT=10022
      - USE_TUNNEL=False
      - ENVIRONMENT=training
      - AGAVE_CACHE_DIR=/home/jovyan/work/.agave
    volumes:
      - ${TRAINING_USERNAME}-training-volume:/home/jovyan/work
      - /var/run/docker.sock:/var/run/docker.sock
    networks:
      - ${TRAINING_USERNAME}-training
    deploy:
      placement:
        constraints:
          - node.labels.training.name == ${TRAINING_EVENT}
          - node.labels.training.user == ${TRAINING_USERNAME}
          - node.labels.environment == training
      labels:
        - training.name=${TRAINING_EVENT}
        - training.user=${TRAINING_USERNAME}
        - environment=training
        - traefik.enable=false
      replicas: 1
      resources:
        limits:
          cpus: "4.0"
          memory: 4G
        reservations:
          cpus: "0.3"
          memory: 256M
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
