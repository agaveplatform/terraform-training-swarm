version: '3.2'

networks:
  ${TRAINING_USERNAME}-training:
  swarm_overlay:
    external:
      name: ${SWARM_OVERLAY_NETWORK_NAME}

volumes:
  ${TRAINING_USERNAME}-jenkins-volume:
    external:
      name: ${TRAINING_USERNAME}-training-volume
  ${TRAINING_USERNAME}-registry-volume:
    external:
      name: ${TRAINING_USERNAME}-registry-volume
#secrets:
#  training/${TRAINING_USERNAME}/hash:
#    external: true

services:
  ${TRAINING_USERNAME}-jenkins:
    image: "${TRAINING_JENKINS_IMAGE}"
    hostname: ${TRAINING_VM_HOSTNAME}
    environment:
      
    volumes:
      - ${TRAINING_USERNAME}-jenkins-volume:/var/jenkins_home
    networks:
      - swarm_overlay
      - ${TRAINING_USERNAME}-training
    ports:
      - target: 8080
        published: 8080
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
        - "traefik.backend=${TRAINING_USERNAME}-jenkins"
        - "traefik.frontend.rule=Host:${TRAINING_VM_HOSTNAME};PathPrefix:/jenkins"
        - "traefik.docker.network=${SWARM_OVERLAY_NETWORK_NAME}"
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
