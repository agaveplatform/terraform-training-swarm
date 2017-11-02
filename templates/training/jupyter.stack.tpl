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

#secrets:
#  training/${TRAINING_USERNAME}/hash:
#    external: true

services:
  # ${TRAINING_USERNAME}-client-init:
  #   image: "${TRAINING_JUPYTER_IMAGE}"
  #   entrypoint: /bin/bash
  #   command: /home/jovyan/bootstrap.sh
  #   hostname: apitest-sandbox.gw17.training.agaveplatform.org
  #   environment:
  #     - VM_MACHINE=${TRAINING_VM_MACHINE}
  #     - VM_IPADDRESS=${TRAINING_VM_ADDRESS}
  #     - VM_HOSTNAME=${TRAINING_VM_HOSTNAME}
  #     - USE_TUNNEL=False
  #     - ENVIRONMENT=training
  #     - AGAVE_USERNAME=${TRAINING_USERNAME}
  #     - AGAVE_CACHE_DIR=/home/jovyan/work/.agave
  #   volumes:
  #     - ${TRAINING_USERNAME}-training-volume:/home/jovyan/work
  #     - ./bootstrap.sh:/home/jovyan/bootstrap.sh
  #   secrets:
  #     - tenant_apitest_pass
  #   deploy:
  #     placement:
  #       constraints:
  #         - node.role == manager
  #     replicas: 1
  #     restart_policy:
  #       condition: none

  ${TRAINING_USERNAME}:
    image: "${TRAINING_JUPYTER_IMAGE}"
    command: start-notebook.sh --NotebookApp.token=''
    hostname: ${TRAINING_VM_HOSTNAME}
    environment:
      - VM_MACHINE=${TRAINING_VM_MACHINE}
      - VM_IPADDRESS=${TRAINING_VM_ADDRESS}
      - VM_HOSTNAME=${TRAINING_VM_HOSTNAME}
      - USE_TUNNEL=False
      - ENVIRONMENT=training
      - AGAVE_USERNAME=${TRAINING_USERNAME}
      - AGAVE_CACHE_DIR=/home/jovyan/work/.agave
      - AGAVE_JSON_PARSER=jq
#      - OAUTH_TOKEN_URL=https://public.agaveapi.co/token
#      - OAUTH_CALLBACK_URL=http://${TRAINING_VM_HOSTNAME}
    volumes:
      - ${TRAINING_USERNAME}-training-volume:/home/jovyan/work
      - /home/agaveops/INSTALL.ipynb:/home/jovyan/INSTALL.ipynb
    networks:
      - swarm_overlay
      - ${TRAINING_USERNAME}-training
    ports:
      - target: 8005
        published: 8005
        protocol: tcp
        mode: host
#    secrets:
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
        - "traefik.port=8005"
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
