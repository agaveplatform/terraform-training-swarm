version: '3.2'

networks:
  monitoring:
    external:
      name: monitoring_monitoring
  application:
    external:
      name: monitoring_application
  logging:
    external:
      name: monitoring_logging
  swarm_overlay:
    external:
      name: ${SWARM_OVERLAY_NETWORK_NAME}

services:

  traefik:
    image: traefik:latest
    hostname: ${TRAINING_EVENT}.training.agaveplatform.org
    command: --configFile=/etc/traefik/traefik.toml
    networks:
      - swarm_overlay
      - application
      - logging
      - monitoring
    ports:
      - "80:80"
      - "443:443"
      - "28443:28443"
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock
      - /home/agaveops/traefik/traefik.toml:/etc/traefik/traefik.toml
      - /home/agaveops/traefik/ssl:/ssl
    labels:
      - traefik.enable=false
    deploy:
      placement:
        constraints:
          - node.role == manager
      labels:
        - ops.service.type=proxy
        - ops.service.name=traefik
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
