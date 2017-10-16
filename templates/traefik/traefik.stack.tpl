version: '3.2'

networks:
  swarm_overlay:
    external:
      name: ${SWARM_OVERLAY_NETWORK_NAME}

services:

  traefik:
    image: traefik:latest
    hostname: ${TRAINING_EVENT}
    command: --debug=True --docker --docker.swarmmode --docker.watch --web --web.address=:28443
    networks:
      - swarm_overlay
    ports:
      - "80:80"
      - "443:443"
      - "28443:28443"
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock
#      - /home/agaveops/traefik/traefik.toml:/etc/traefik/traefik.toml
#      - /home/agaveops/traefik/ssl:/ssl
    labels:
      - traefik.enable=false
    deploy:
      mode: global
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
